# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApoForm do
  let(:fake_tags_client) { instance_double(Dor::Services::Client::AdministrativeTags, create: true) }

  before do
    allow(instance).to receive(:tags_client).and_return(fake_tags_client)
  end

  context 'with a model (update)' do
    let(:instance) { described_class.new(apo) }
    let(:agreement) { instantiate_fixture('dd327qr3670', Dor::Item) }
    let(:apo) { instantiate_fixture('zt570tx3016', Dor::AdminPolicyObject) }
    let(:md_info) do
      {
        copyright: 'My copyright statement',
        use: 'My use and reproduction statement',
        title: +'My title',
        desc_md: 'MODS',
        metadata_source: 'DOR',
        agreement: agreement.pid,
        workflow: 'registrationWF',
        default_object_rights: 'world',
        use_license: 'by-nc'
      }
    end

    before do
      allow(apo).to receive(:new_record?).and_return(false) # instantiate_record creates unsaved objects
      allow(Dor).to receive(:find).with(agreement.pid, cast: true).and_return(agreement)
    end

    describe '#sync' do
      let(:license_info) { Dor::CreativeCommonsLicenseService.property(md_info[:use_license]) }

      it 'sets clean APO metadata for defaultObjectRights' do
        instance.validate(md_info)
        instance.sync

        expect(apo.mods_title).to           eq(md_info[:title])
        expect(apo.desc_metadata_format).to eq(md_info[:desc_md])
        expect(apo.metadata_source).to      eq(md_info[:metadata_source])
        expect(apo.agreement).to            eq(md_info[:agreement])
        expect(apo.default_workflows).to    eq([md_info[:workflow]])
        expect(apo.default_rights).to       eq(md_info[:default_object_rights])
        expect(apo.use_license).to          eq(md_info[:use_license])
        expect(apo.use_license_uri).to      eq(license_info.uri)
        expect(apo.use_license_human).to    eq(license_info.label)
        expect(apo.copyright_statement).to  eq(md_info[:copyright])
        expect(apo.use_statement).to        eq(md_info[:use])
        doc = Nokogiri::XML(File.read('spec/fixtures/apo_defaultObjectRights_clean.xml'))
        expect(apo.defaultObjectRights.content).to be_equivalent_to(doc)
      end

      it 'handles no use license' do
        md_info[:use_license] = ' '
        instance.validate(md_info)
        instance.sync
        expect(apo.use_license).to          be_blank
        expect(apo.use_license_uri).to      be_nil
        expect(apo.use_license_human).to    be_blank
      end

      it 'handles no copyright statement' do
        md_info[:copyright] = ' '
        instance.validate(md_info)
        instance.sync
        expect(apo.copyright_statement).to be_nil
      end

      it 'handles UTF8 copyright statement' do
        md_info[:copyright] = 'Copyright © All Rights Reserved.'
        instance.validate(md_info)
        instance.sync
        expect(apo.copyright_statement).to eq(md_info[:copyright])
      end

      context 'when the user provides no statement' do
        it 'updates it to nil' do
          md_info[:use] = ' '
          instance.validate(md_info)
          instance.sync
          expect(apo.use_statement).to be_nil
        end
      end
    end

    describe '#validate' do
      it 'errors out if no workflow' do
        md_info[:workflow] = ' '
        instance.validate(md_info)

        expect { instance.sync }.to raise_error(ArgumentError)
      end
    end

    describe '#permissions' do
      subject { instance.permissions }

      it 'has the defaults' do
        expect(subject).to match_array [
          { name: 'developers', type: 'group', access: 'manage' },
          { name: 'pmag-staff', type: 'group', access: 'manage' },
          { name: 'smpl-staff', type: 'group', access: 'manage' },
          { name: 'dpg-staff', type: 'group', access: 'manage' },
          { name: 'argo-access-spec', type: 'group', access: 'manage' },
          { name: 'lmcrae', type: 'person', access: 'manage' }
        ]
      end
    end

    describe '#default_workflow' do
      subject { instance.default_workflow }

      it { is_expected.to eq 'digitizationWF' }
    end

    describe '#agreement' do
      subject { instance.agreement }

      it { is_expected.to eq agreement.pid }
    end

    describe '#use_license' do
      subject { instance.use_license }

      it { is_expected.to eq 'by-nc-sa' }
    end

    describe '#default_rights' do
      subject { instance.default_rights }

      it { is_expected.to eq 'world' }
    end

    describe '#desc_metadata_format' do
      subject { instance.desc_metadata_format }

      it { is_expected.to eq 'MODS' }
    end

    describe '#metadata_source' do
      subject { instance.metadata_source }

      it { is_expected.to be_nil }
    end

    describe '#use_statement' do
      subject { instance.use_statement }

      it { is_expected.to start_with 'Rights are owned by Stanford University Libraries' }
    end

    describe '#copyright_statement' do
      subject { instance.copyright_statement }

      it { is_expected.to eq 'Additional copyright info' }
    end

    describe '#mods_title' do
      subject { instance.mods_title }

      it { is_expected.to eq 'Ampex' }
    end

    describe '#default_collection_objects' do
      subject { instance.default_collection_objects }

      it { is_expected.to eq [] }
    end

    describe '#to_param' do
      subject { instance.to_param }

      it { is_expected.to eq 'druid:zt570tx3016' }
    end

    describe '#license_options' do
      subject { instance.license_options }

      it 'is an array of the options' do
        expect(subject).to be_a Array
        expect(subject[0]).to be_a Array
        expect(subject.size).to eq 11
      end
    end
  end

  context 'new model' do
    let(:instance) { described_class.new(Dor::AdminPolicyObject.new) }

    describe '#permissions' do
      subject { instance.permissions }

      it 'has the defaults' do
        expect(subject).to match_array [
          { name: 'developer', type: 'group', access: 'manage' },
          { name: 'service-manager', type: 'group', access: 'manage' },
          { name: 'metadata-staff', type: 'group', access: 'manage' }
        ]
      end
    end

    describe '#default_workflow' do
      subject { instance.default_workflow }

      it { is_expected.to eq 'registrationWF' }
    end

    describe '#use_license' do
      subject { instance.use_license }

      it { is_expected.to be_nil }
    end

    describe '#default_rights' do
      subject { instance.default_rights }

      it { is_expected.to eq 'world' }
    end

    describe '#desc_metadata_format' do
      subject { instance.desc_metadata_format }

      it { is_expected.to eq 'MODS' }
    end

    describe '#metadata_source' do
      subject { instance.metadata_source }

      it { is_expected.to eq 'DOR' }
    end

    describe '#use_statement' do
      subject { instance.use_statement }

      it { is_expected.to eq '' }
    end

    describe '#copyright_statement' do
      subject { instance.copyright_statement }

      it { is_expected.to eq '' }
    end

    describe '#mods_title' do
      subject { instance.mods_title }

      it { is_expected.to eq '' }
    end

    describe '#default_collection_objects' do
      subject { instance.default_collection_objects }

      it { is_expected.to eq [] }
    end

    describe '#to_param' do
      subject { instance.to_param }

      it { is_expected.to be_nil }
    end

    describe '#license_options' do
      subject { instance.license_options }

      it 'is an array of the options' do
        expect(subject).to be_a Array
        expect(subject[0]).to be_a Array
        expect(subject.size).to eq 11
      end
    end

    describe '#save' do
      let(:apo) { instantiate_fixture('zt570tx3016', Dor::AdminPolicyObject) }
      let(:agreement) { instantiate_fixture('dd327qr3670', Dor::Item) }
      let(:collection) { instantiate_fixture('pb873ty1662', Dor::Collection) }

      let(:base_params) do
        { # These data mimic the APO registration form
          'title' => +'New APO Title',
          'agreement' => agreement.pid,
          'desc_md' => 'MODS',
          'metadata_source' => 'DOR',
          permissions: {
            '0' => { access: 'manage', name: 'developers', type: 'group' },
            '1' => { access: 'manage', name: 'dpg-staff', type: 'group' },
            '2' => { access: 'view', name: 'viewer-role', type: 'group' },
            '3' => { access: 'view', name: 'forensics-staff', type: 'group' }
          },
          'collection_radio' => 'create',
          'collection_title' => 'col title',
          'collection_rights' => 'world',
          'collection_abstract' => '',
          'default_object_rights' => 'world',
          'use' => '',
          'copyright' => '',
          'use_license' => 'by-nc',
          'workflow' => 'accessionWF',
          'register' => ''
        }.with_indifferent_access
      end

      let(:workflow_client) { instance_double(Dor::Workflow::Client, status: true) }
      let(:created_apo) do
        Cocina::Models::AdminPolicy.new(externalIdentifier: 'druid:zt570tx3016',
                                        type: Cocina::Models::Vocab.admin_policy,
                                        label: '',
                                        version: 1,
                                        administrative: {}).to_json
      end

      let(:created_collection) do
        Cocina::Models::Collection.new(externalIdentifier: 'druid:pb873ty1662',
                                       type: Cocina::Models::Vocab.collection,
                                       label: '',
                                       version: 1,
                                       access: {}).to_json
      end

      before do
        allow(Dor::Workflow::Client).to receive(:new).and_return(workflow_client)
        expect(Dor).to receive(:find).with(agreement.pid, cast: true).and_return(agreement)
        expect(Dor).to receive(:find).with(collection.pid).and_return(collection)
        expect(collection).to receive(:save)
        expect(Argo::Indexer).to receive(:reindex_pid_remotely).twice

        expect(Dor).to receive(:find).with(apo.pid).and_return(apo)
        expect(apo).to receive(:save)
        expect(apo).to receive(:add_roleplayer).exactly(4).times

        stub_request(:post, 'http://localhost:3003/v1/objects')
          .with(
            body: '{"type":"http://cocina.sul.stanford.edu/models/admin_policy.jsonld",' \
            '"label":"New APO Title","version":1,' \
            '"administrative":{"defaultObjectRights":"\\u003c?xml version=\\"1.0\\" encoding=\\"UTF-8\\"?\\u003e' \
            '\\u003crightsMetadata\\u003e\\u003caccess type=\\"discover\\"\\u003e\\u003cmachine\\u003e' \
            '\\u003cworld/\\u003e\\u003c/machine\\u003e' \
            '\\u003c/access\\u003e\\u003caccess type=\\"read\\"\\u003e\\u003cmachine\\u003e\\u003cworld/\\u003e\\u003c/machine\\u003e' \
            '\\u003c/access\\u003e\\u003cuse\\u003e\\u003chuman type=\\"useAndReproduction\\"/\\u003e\\u003chuman type=\\"creativeCommons\\"/' \
            '\\u003e\\u003cmachine type=\\"creativeCommons\\" uri=\\"\\"/\\u003e\\u003chuman type=\\"openDataCommons\\"/' \
            '\\u003e\\u003cmachine type=\\"openDataCommons\\" uri=\\"\\"/\\u003e\\u003c/use\\u003e\\u003ccopyright\\u003e\\u003chuman/' \
            '\\u003e\\u003c/copyright\\u003e\\u003c/rightsMetadata\\u003e","hasAdminPolicy":"druid:hv992ry2431"}}'
          )
          .to_return(status: 200, body: created_apo, headers: {})

        expect(workflow_client).to receive(:create_workflow_by_name)
          .with(apo.pid, 'accessionWF', version: '1')
        expect(apo).to receive(:"use_license=").with(params['use_license'])

        # verify that the collection is also created
        expect(apo).to receive(:add_default_collection).with(collection.pid)

        stub_request(:post, 'http://localhost:3003/v1/objects')
          .with(
            body: '{"type":"http://cocina.sul.stanford.edu/models/collection.jsonld",' \
            '"label":"col title","version":1,"access":{"access":"world","download":"none"},' \
            '"administrative":{"hasAdminPolicy":"druid:zt570tx3016"}}'
          )
          .to_return(status: 200, body: created_collection)

        expect(workflow_client).to receive(:create_workflow_by_name).with(collection.pid, 'accessionWF', version: '1')
      end

      context 'with tags in the params' do
        let(:params) { base_params.merge(tag: tags) }
        let(:tags) { ['One : Two', 'Two : Three'] }

        it 'hits the dor-services-app administrative tags endpoint to add tags' do
          instance.validate(params)
          instance.save
          expect(fake_tags_client).to have_received(:create).once.with(tags: tags)
        end
      end

      context 'without tags in the params' do
        let(:params) { base_params }

        it 'hits the registration service to register both an APO and a collection' do
          instance.validate(params)
          instance.save
          expect(fake_tags_client).not_to have_received(:create)
        end
      end
    end
  end
end

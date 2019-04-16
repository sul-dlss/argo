# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ApoForm do
  let(:instance) { described_class.new }

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
      allow(Dor).to receive(:find).with(agreement.pid, cast: true).and_return(agreement)
    end

    describe '#sync' do
      let(:license_info) { CreativeCommonsLicenseService.property(md_info[:use_license]) }

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

      it 'handles no use statement' do
        md_info[:use] = ' '
        instance.validate(md_info)
        instance.sync
        expect(apo.use_statement).to be_nil
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

  context 'no model (new)' do
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

      it { is_expected.to eq '' }
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

      it { is_expected.to be_nil }
    end

    describe '#copyright_statement' do
      subject { instance.copyright_statement }

      it { is_expected.to be_nil }
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

      let(:params) do
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
          'collection_abstract' => '',
          'default_object_rights' => 'world',
          'use' => '',
          'copyright' => '',
          'use_license' => 'by-nc',
          'workflow' => 'accessionWF',
          'register' => ''
        }.with_indifferent_access
      end

      before do
        expect(Dor).to receive(:find).with(agreement.pid, cast: true).and_return(agreement)
        expect(Dor).to receive(:find).with(collection.pid).and_return(collection)
        expect(collection).to receive(:save)
        expect(Dor).to receive(:find).with(apo.pid).and_return(apo)
        expect(apo).to receive(:save)
      end

      it 'hits the registration service to register both an APO and a collection' do
        # verify that an APO is registered
        expect(apo).to receive(:add_roleplayer).exactly(4).times
        expect(Dor::Services::Client.objects).to receive(:register) do |args|
          expect(args[:params]).to match a_hash_including(
            label: 'New APO Title',
            object_type: 'adminPolicy',
            admin_policy: 'druid:hv992ry2431', # Uber-APO
            workflow_priority: '70'
          )
          expect(args[:metadata_source]).to be_nil # descMD is created via the form
          { pid: apo.pid }
        end
        expect(apo).to receive(:"use_license=").with(params['use_license'])

        # verify that the collection is also created
        expect(apo).to receive(:add_default_collection).with(collection.pid)
        expect(Dor::Services::Client.objects).to receive(:register) do |args|
          expect(args[:params]).to match a_hash_including(
            label: 'col title',
            object_type: 'collection',
            admin_policy: apo.pid,
            workflow_priority: '65'
          )
          { pid: collection.pid }
        end

        instance.validate(params)
        instance.save
      end
    end
  end
end

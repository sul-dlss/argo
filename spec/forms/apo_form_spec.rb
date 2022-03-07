# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApoForm do
  let(:search_service) { instance_double(Blacklight::SearchService) }
  let(:instance) { described_class.new(apo, search_service: search_service) }
  let(:apo) do
    Cocina::Models::AdminPolicy.new(
      type: Cocina::Models::Vocab.admin_policy,
      externalIdentifier: 'druid:zt570qh4444',
      version: 1,
      administrative: administrative,
      label: 'My title',
      description: { title: [{ value: 'Stored title' }], purl: 'https://purl.stanford.edu/zt570qh4444' }
    )
  end

  let(:administrative) do
    {
      hasAdminPolicy: 'druid:xx666zz7777',
      hasAgreement: 'druid:hp308wm0436',
      registrationWorkflow: ['registrationWF'],
      defaultAccess: default_access,
      collectionsForRegistration: %w[druid:xf330kz3480 druid:zn588xt6079 druid:zq557wp0848 druid:tw619vm5957
                                     druid:ts734sd4095 druid:sx487cw2287 druid:pv392zr2847 druid:sh776dy9514
                                     druid:dy736ft1835 druid:kj087tz6537 druid:qs995zb1355 druid:yk518vd0459]
    }
  end
  let(:default_access) { {} }

  context 'with a persisted model (update)' do
    let(:agreement_id) { 'druid:dd327rv8888' }

    describe '#permissions' do
      subject { instance.permissions }

      let(:administrative) do
        {
          hasAdminPolicy: 'druid:xx666zz7777',
          hasAgreement: 'druid:hp308wm0436',
          registrationWorkflow: ['registrationWF'],
          roles: [
            {
              members: [
                { identifier: 'dlss:developers', type: 'workgroup' },
                { identifier: 'dlss:pmag-staff', type: 'workgroup' },
                { identifier: 'dlss:smpl-staff', type: 'workgroup' },
                { identifier: 'dlss:dpg-staff', type: 'workgroup' },
                { identifier: 'dlss:argo-access-spec', type: 'workgroup' }
              ],
              name: 'dor-apo-manager'
            }
          ],
          defaultAccess: { access: 'world', download: 'world' }
        }
      end

      it 'has the defaults' do
        expect(subject).to match_array [
          { name: 'developers', type: 'group', access: 'manage' },
          { name: 'pmag-staff', type: 'group', access: 'manage' },
          { name: 'smpl-staff', type: 'group', access: 'manage' },
          { name: 'dpg-staff', type: 'group', access: 'manage' },
          { name: 'argo-access-spec', type: 'group', access: 'manage' }
        ]
      end
    end

    describe '#default_workflows' do
      subject { instance.default_workflows }

      let(:administrative) do
        {
          hasAdminPolicy: 'druid:xx666zz7777',
          hasAgreement: 'druid:hp308wm0436',
          registrationWorkflow: %w[digitizationWF goobiWF],
          defaultAccess: { access: 'world', download: 'world' }
        }
      end

      it { is_expected.to eq %w[digitizationWF goobiWF] }
    end

    describe '#agreement_object_id' do
      subject { instance.agreement_object_id }

      let(:administrative) do
        {
          hasAdminPolicy: 'druid:xx666zz7777',
          registrationWorkflow: ['digitizationWF'],
          hasAgreement: 'druid:dd327rv8888',
          defaultAccess: { access: 'world', download: 'world' }
        }
      end

      it { is_expected.to eq agreement_id }
    end

    describe '#use_license' do
      subject { instance.use_license }

      let(:default_access) { { license: 'https://creativecommons.org/licenses/by-nc-sa/3.0/legalcode' } }

      it { is_expected.to eq 'https://creativecommons.org/licenses/by-nc-sa/3.0/legalcode' }
    end

    describe '#default_rights' do
      subject { instance.default_rights }

      let(:default_access) { { access: 'world' } }

      it { is_expected.to eq 'world' }

      describe 'stanford variation' do
        let(:administrative) do
          {
            hasAdminPolicy: 'druid:xx666zz7777',
            hasAgreement: 'druid:hp308wm0436',
            defaultAccess: {
              access: 'stanford',
              download: 'none'
            }
          }
        end

        it { is_expected.to eq 'stanford-nd' }
      end

      describe 'location based' do
        let(:administrative) do
          {
            hasAdminPolicy: 'druid:xx666zz7777',
            hasAgreement: 'druid:hp308wm0436',
            defaultAccess: {
              access: 'location-based',
              readLocation: 'ars'
            }
          }
        end

        it { is_expected.to eq 'loc:ars' }
      end

      describe 'controlled digital lending' do
        let(:administrative) do
          {
            hasAdminPolicy: 'druid:xx666zz7777',
            hasAgreement: 'druid:hp308wm0436',
            defaultAccess: {
              controlledDigitalLending: true
            }
          }
        end

        it { is_expected.to eq 'cdl-stanford-nd' }
      end
    end

    describe '#use_statement' do
      subject { instance.use_statement }

      let(:default_access) { { useAndReproductionStatement: 'Rights are owned by Stanford University Libraries' } }

      it { is_expected.to eq 'Rights are owned by Stanford University Libraries' }
    end

    describe '#copyright_statement' do
      subject { instance.copyright_statement }

      let(:default_access) { { copyright: 'Additional copyright info' } }

      it { is_expected.to eq 'Additional copyright info' }
    end

    describe '#title' do
      subject { instance.title }

      it { is_expected.to eq 'Stored title' }
    end

    describe '#to_param' do
      subject { instance.to_param }

      it { is_expected.to eq 'druid:zt570qh4444' }
    end

    describe '#license_options' do
      subject { instance.license_options }

      it 'is an array of the options' do
        expect(subject).to be_a Array
        expect(subject[0]).to be_a Array
        expect(subject.size).to eq 29
      end
    end
  end

  context 'with an unsaved model' do
    let(:apo) { nil }

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

    describe '#default_workflows' do
      subject { instance.default_workflows }

      it { is_expected.to eq ['registrationWF'] }
    end

    describe '#use_license' do
      subject { instance.use_license }

      it { is_expected.to be_nil }
    end

    describe '#default_rights' do
      subject { instance.default_rights }

      it { is_expected.to eq 'world' }
    end

    describe '#use_statement' do
      subject { instance.use_statement }

      it { is_expected.to be_nil }
    end

    describe '#copyright_statement' do
      subject { instance.copyright_statement }

      it { is_expected.to be_nil }
    end

    describe '#title' do
      subject { instance.title }

      it { is_expected.to be_nil }
    end

    describe '#license_options' do
      subject { instance.license_options }

      it 'is an array of the options' do
        expect(subject).to be_a Array
        expect(subject[0]).to be_a Array
        expect(subject.size).to eq 29
      end
    end
  end

  describe '#default_collection_objects' do
    subject { instance.default_collection_objects }

    let(:default_collection_druids) { administrative[:collectionsForRegistration] }
    let(:default_collection_objects) do
      default_collection_druids.map do |druid|
        label = druid[-1].to_i.even? ? druid : druid.upcase # introduce arbitrary mixed case to test sorting
        instance_double(SolrDocument, label: label)
      end
    end
    let(:search_service_result) { [nil, default_collection_objects] }
    let(:search_service) { instance_double(Blacklight::SearchService) }

    before do
      allow(search_service).to receive(:fetch).with(default_collection_druids, rows: default_collection_druids.size)
                                              .and_return(search_service_result)
    end

    it { is_expected.to eq(default_collection_objects.sort_by { |solr_doc| solr_doc.label.downcase }) }
  end
end

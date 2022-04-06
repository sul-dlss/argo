# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AdminPolicyChangeSetPersister do
  let(:fake_tags_client) { instance_double(Dor::Services::Client::AdministrativeTags, create: true) }
  let(:instance) { described_class.new(apo, change_set) }

  before do
    allow(instance).to receive(:tags_client).and_return(fake_tags_client)
  end

  context 'with a persisted model (update)' do
    let(:apo) do
      Cocina::Models::AdminPolicy.new(
        externalIdentifier: 'druid:zt570qh4444',
        version: 1,
        administrative: administrative,
        label: 'My title',
        type: Cocina::Models::ObjectType.admin_policy,
        description: {
          title: [{ value: 'Exsiting title' }],
          purl: 'https://purl.stanford.edu/zt570qh4444'
        }
      )
    end
    let(:administrative) do
      {
        hasAdminPolicy: 'druid:xx666zz7777',
        hasAgreement: 'druid:hp308wm0436',
        accessTemplate: { view: 'world', download: 'world' }
      }
    end

    let(:use_statement) { 'My use and reproduction statement' }
    let(:copyright_statement) { 'My copyright statement' }
    let(:agreement_object_id) { 'druid:dd327rv8888' }
    let(:use_license) { 'https://creativecommons.org/licenses/by-nc/3.0/legalcode' }
    let(:default_workflows) { ['registrationWF'] }

    let(:change_set) do
      instance_double(ApoForm,
                      copyright_statement: copyright_statement,
                      use_statement: use_statement,
                      title: 'My title',
                      agreement_object_id: agreement_object_id,
                      default_workflows: default_workflows,
                      default_rights: 'world',
                      use_license: use_license,
                      permissions: { '0' => { name: 'developer', access: 'manage', type: 'group' },
                                     '1' => { name: 'service-manager', access: 'manage', type: 'group' },
                                     '2' => { name: 'metadata-staff', access: 'manage', type: 'group' },
                                     '3' => { name: 'justins', access: 'view', type: 'group' } },
                      collections_for_registration: { '0' => { id: 'druid:zj785yp4820' } },
                      collection_radio: 'none',
                      collection: {})
    end

    describe '#sync' do
      subject(:result) { instance.sync }

      it 'sets clean APO metadata for accessTemplate' do
        expect(result.to_h).to eq(
          Cocina::Models::AdminPolicy.new(
            administrative: {
              accessTemplate: {
                view: 'world',
                controlledDigitalLending: false,
                download: 'world',
                location: nil,
                copyright: 'My copyright statement',
                license: 'https://creativecommons.org/licenses/by-nc/3.0/legalcode',
                useAndReproductionStatement: 'My use and reproduction statement'
              },
              collectionsForRegistration: ['druid:zj785yp4820'],
              hasAdminPolicy: 'druid:xx666zz7777',
              hasAgreement: 'druid:dd327rv8888',
              registrationWorkflow: ['registrationWF'],
              roles: [
                {
                  members: [
                    { identifier: 'sdr:developer', type: 'workgroup' },
                    { identifier: 'sdr:service-manager', type: 'workgroup' },
                    { identifier: 'sdr:metadata-staff', type: 'workgroup' }
                  ],
                  name: 'dor-apo-manager'
                },
                {
                  members: [
                    { identifier: 'sdr:justins', type: 'workgroup' }
                  ],
                  name: 'dor-apo-viewer'
                }
              ]
            },
            description: {
              title: [{ value: 'My title' }],
              purl: 'https://purl.stanford.edu/zt570qh4444'
            },
            externalIdentifier: 'druid:zt570qh4444',
            label: 'My title',
            type: Cocina::Models::ObjectType.admin_policy,
            version: 1
          ).to_h
        )
      end
    end

    context 'when registered by is set' do
      subject(:update) { instance.update }

      let(:object_client) { instance_double(Dor::Services::Client::Object, update: cocina_model) }
      let(:cocina_model) do
        instance_double(Cocina::Models::DRO, externalIdentifier: 'druid:999')
      end
      let(:change_set) do
        instance_double(ApoForm,
                        copyright_statement: copyright_statement,
                        use_statement: use_statement,
                        title: 'My title',
                        agreement_object_id: agreement_object_id,
                        default_workflows: default_workflows,
                        default_rights: 'world',
                        use_license: use_license,
                        permissions: {},
                        registered_by: 'jcoyne85',
                        collection_radio: 'none',
                        collections_for_registration: {},
                        collection: {})
      end

      before do
        allow(Dor::Services::Client).to receive(:object).and_return(object_client)
      end

      it 'hits the dor-services-app administrative tags endpoint to add tags' do
        update
        expect(fake_tags_client).to have_received(:create).once.with(tags: ['Registered By : jcoyne85'])
      end
    end
  end
end

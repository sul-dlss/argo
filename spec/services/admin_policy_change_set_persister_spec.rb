# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AdminPolicyChangeSetPersister do
  let(:fake_tags_client) { instance_double(Dor::Services::Client::AdministrativeTags, create: true) }

  let(:use_statement) { 'My use and reproduction statement' }
  let(:copyright_statement) { 'My copyright statement' }
  let(:agreement_object_id) { 'druid:dd327rv8888' }
  let(:use_license) { 'https://creativecommons.org/licenses/by-nc/3.0/' }
  let(:default_workflows) { ['registrationWF'] }
  let(:administrative) do
    {
      hasAdminPolicy: 'druid:xx666zz7777'
    }
  end

  let(:registered) do
    Cocina::Models::AdminPolicy.new(
      externalIdentifier: 'druid:zt570qh4444',
      version: 1,
      administrative: administrative,
      label: 'My title',
      type: Cocina::Models::Vocab.admin_policy,
      description: {
        title: [{ value: 'Exsiting title' }]
      }
    )
  end

  before do
    allow(instance).to receive(:tags_client).and_return(fake_tags_client)
  end

  describe '#sync' do
    subject(:result) { instance.sync }

    let(:instance) { described_class.new(registered, change_set) }

    let(:change_set) do
      instance_double(AdminPolicyChangeSet,
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
                      collection_radio: 'none',
                      collection: {})
    end

    let(:default_object_rights) do
      '<?xml version="1.0" encoding="UTF-8"?><rightsMetadata>' \
      '<access type="discover"><machine><world/></machine></access>' \
      '<access type="read"><machine><world/></machine></access>' \
      '<use><human type="useAndReproduction"/><human type="creativeCommons"/>' \
      '<machine type="creativeCommons" uri=""/><human type="openDataCommons"/>' \
      '<machine type="openDataCommons" uri=""/></use>' \
      '<copyright><human/></copyright></rightsMetadata>'
    end

    it 'sets clean APO metadata for defaultObjectRights' do
      expect(result.to_h).to eq(
        administrative: {
          defaultAccess: {
            access: 'world',
            controlledDigitalLending: false,
            download: 'world',
            readLocation: nil,
            copyright: 'My copyright statement',
            license: 'https://creativecommons.org/licenses/by-nc/3.0/',
            useAndReproductionStatement: 'My use and reproduction statement'
          },
          defaultObjectRights: default_object_rights,
          hasAdminPolicy: 'druid:xx666zz7777',
          referencesAgreement: 'druid:dd327rv8888',
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
          title: [{ value: 'My title' }]
        },
        externalIdentifier: 'druid:zt570qh4444',
        label: 'My title',
        type: 'http://cocina.sul.stanford.edu/models/admin_policy.jsonld',
        version: 1
      )
    end
  end

  describe '#create' do
    subject(:update) { instance.create }

    let(:instance) { described_class.new(nil, change_set) }
    let(:object_client) { instance_double(Dor::Services::Client::Object, update: cocina_model) }
    let(:cocina_model) do
      instance_double(Cocina::Models::DRO, externalIdentifier: 'druid:999')
    end
    let(:change_set) do
      instance_double(AdminPolicyChangeSet,
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
                      collection: {})
    end

    let(:workflow_client) { instance_double(Dor::Workflow::Client, create_workflow_by_name: true) }

    before do
      allow(Dor::Services::Client).to receive(:object).and_return(object_client)
      allow(Dor::Services::Client.objects).to receive(:register).and_return(registered)
      allow(WorkflowClientFactory).to receive(:build).and_return(workflow_client)
    end

    it 'hits the dor-services-app administrative tags endpoint to add tags' do
      update
      expect(fake_tags_client).to have_received(:create).once.with(tags: ['Registered By : jcoyne85'])
      expect(workflow_client).to have_received(:create_workflow_by_name).with('druid:999', 'accessionWF', version: '1')
    end
  end
end

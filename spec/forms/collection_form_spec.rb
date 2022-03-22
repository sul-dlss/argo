# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CollectionForm do
  let(:apo_pid) { 'druid:zt570qh4444' }
  let(:uber_apo_id) { 'druid:hv992ry2431' }
  let(:collection_id) { 'druid:gg232vv1111' }

  context 'when creating collection' do
    let(:instance) { described_class.new }

    let(:title) { 'collection title' }
    let(:abstract) { 'this is the abstract' }
    let(:description) do
      {
        title: [{ value: title, status: 'primary' }],
        note: [{ value: abstract, type: 'summary' }],
        purl: 'https://purl.stanford.edu/zz666yy9999'
      }
    end
    let(:expected_body_hash) do
      {
        type: Cocina::Models::ObjectType.collection,
        label: title,
        version: 1,
        access: { view: 'dark' },
        administrative: { hasAdminPolicy: 'druid:zt570qh4444' },
        description: description
      }
    end
    let(:created_collection) do
      Cocina::Models::Collection.new(externalIdentifier: collection_id,
                                     type: Cocina::Models::ObjectType.collection,
                                     label: '',
                                     version: 1,
                                     access: {},
                                     identification: {},
                                     administrative: { hasAdminPolicy: 'druid:zt570qh4444' },
                                     description: description).to_json
    end
    let(:workflow_client) { instance_double(Dor::Workflow::Client, create_workflow_by_name: true) }

    before do
      allow(Dor::Workflow::Client).to receive(:new).and_return(workflow_client)
      allow(instance).to receive(:register_model).and_call_original
      allow(instance).to receive(:sync)
    end

    context 'when fields are missing' do
      let(:params) do
        {
          collection_title: '',
          collection_abstract: '',
          collection_rights: 'dark'
        }.with_indifferent_access
      end

      it "doesn't validate" do
        expect(instance.validate(params.merge(apo_pid: apo_pid))).to be false
        expect(instance.errors.full_messages).to eq ['missing collection_title or collection_catkey']
      end
    end

    context 'when metadata_source is label' do
      let(:params) do
        {
          collection_title: title,
          collection_abstract: abstract,
          collection_rights: 'dark'
        }.with_indifferent_access
      end

      let(:request_description) do
        {
          title: [{ value: title, status: 'primary' }],
          note: [{ value: abstract, type: 'summary' }]
        }
      end
      let(:expected_request_body_hash) do
        {
          type: Cocina::Models::ObjectType.collection,
          label: title,
          version: 1,
          access: { view: 'dark' },
          administrative: { hasAdminPolicy: 'druid:zt570qh4444' },
          description: request_description
        }
      end

      before do
        stub_request(:post, "#{Settings.dor_services.url}/v1/objects")
          .with(body: Cocina::Models::RequestCollection.new(expected_request_body_hash).to_json)
          .to_return(status: 200, body: created_collection, headers: {})
      end

      it 'creates a collection from title/abstract by registering the collection, without adding the abstract to descMetadata' do
        instance.validate(params.merge(apo_pid: apo_pid))
        instance.save

        expect(instance).to have_received(:register_model)
        expect(instance).not_to have_received(:sync)
        expect(workflow_client).to have_received(:create_workflow_by_name).with(collection_id, 'accessionWF', version: '1')
      end
    end

    context 'when metadata_source is catkey' do
      let(:params) do
        {
          collection_rights_catkey: 'dark',
          collection_catkey: '99998'
        }.with_indifferent_access
      end

      before do
        expected_body_hash[:identification] = { catalogLinks: [{ catalog: 'symphony', catalogRecordId: '99998' }] }
        expected_body_hash.delete(:description)
        expected_body_hash[:label] = ':auto'
        stub_request(:post, "#{Settings.dor_services.url}/v1/objects")
          .with(body: Cocina::Models::RequestCollection.new(expected_body_hash).to_json)
          .to_return(status: 200, body: created_collection, headers: {})
      end

      it 'creates a collection from catkey by registering the collection, without adding the abstract to descMetadata' do
        instance.validate(params.merge(apo_pid: apo_pid))
        instance.save

        expect(instance).to have_received(:register_model)
        expect(instance).not_to have_received(:sync)
        expect(workflow_client).to have_received(:create_workflow_by_name).with(collection_id, 'accessionWF', version: '1')
      end
    end
  end
end

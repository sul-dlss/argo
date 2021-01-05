# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CollectionForm do
  let(:apo) { instance_double(Dor::AdminPolicyObject, pid: 'druid:zt570qh4444') }

  before do
    allow(Argo::Indexer).to receive(:reindex_pid_remotely)
  end

  context 'when creating collection' do
    let(:instance) { described_class.new(Dor::Collection.new) }
    let(:collection_from_fixture) { Dor.find(cocina_collection.externalIdentifier) }
    let(:cocina_collection) { FactoryBot.create_for_repository(:collection) }

    let(:title) { 'collection title' }
    let(:abstract) { 'this is the abstract' }
    let(:description) do
      {
        title: [{ value: title, status: 'primary' }],
        note: [{ value: abstract, type: 'summary' }]
      }
    end
    let(:expected_body_hash) do
      {
        type: 'http://cocina.sul.stanford.edu/models/collection.jsonld',
        label: title,
        version: 1,
        access: { access: 'dark' },
        administrative: { hasAdminPolicy: 'druid:zt570qh4444' },
        description: description
      }
    end
    let(:created_collection) do
      Cocina::Models::Collection.new(externalIdentifier: cocina_collection.externalIdentifier,
                                     type: Cocina::Models::Vocab.collection,
                                     label: '',
                                     version: 1,
                                     access: {},
                                     description: description).to_json
    end
    let(:mock_desc_md_ds) { double(Dor::DescMetadataDS, :abstract= => true) }
    let(:workflow_client) { instance_double(Dor::Workflow::Client, create_workflow_by_name: true) }

    before do
      allow(Dor).to receive(:find).with(cocina_collection.externalIdentifier).and_return(collection_from_fixture)
      allow(Dor).to receive(:find).with(apo.pid).and_return(apo)
      allow(Dor::Workflow::Client).to receive(:new).and_return(workflow_client)
      allow(collection_from_fixture).to receive(:descMetadata).and_return(mock_desc_md_ds)
      allow(instance).to receive(:register_model).and_call_original
      allow(instance).to receive(:sync)
    end

    context 'when metadata_source is label' do
      let(:params) do
        {
          collection_title: title,
          collection_abstract: abstract,
          collection_rights: 'dark'
        }.with_indifferent_access
      end

      before do
        stub_request(:post, "#{Settings.dor_services.url}/v1/objects")
          .with(body: JSON.generate(expected_body_hash))
          .to_return(status: 200, body: created_collection, headers: {})
      end

      it 'creates a collection from title/abstract by registering the collection, without adding the abstract to descMetadata' do
        instance.validate(params.merge(apo_pid: apo.pid))
        instance.save

        expect(instance).to have_received(:register_model)
        expect(instance).not_to have_received(:sync)
        expect(workflow_client).to have_received(:create_workflow_by_name).with(cocina_collection.externalIdentifier, 'accessionWF', version: '1')
        expect(mock_desc_md_ds).not_to have_received(:abstract=).with(abstract)
        expect(Argo::Indexer).to have_received(:reindex_pid_remotely)
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
          .with(body: JSON.generate(expected_body_hash))
          .to_return(status: 200, body: created_collection, headers: {})
      end

      it 'creates a collection from catkey by registering the collection, without adding the abstract to descMetadata' do
        instance.validate(params.merge(apo_pid: apo.pid))
        instance.save

        expect(instance).to have_received(:register_model)
        expect(instance).not_to have_received(:sync)
        expect(workflow_client).to have_received(:create_workflow_by_name).with(cocina_collection.externalIdentifier, 'accessionWF', version: '1')
        expect(mock_desc_md_ds).not_to have_received(:abstract=).with(abstract)
        expect(Argo::Indexer).to have_received(:reindex_pid_remotely)
      end
    end
  end

  context 'when updating a collection' do
    let(:instance) { described_class.new(existing_collection) }
    let(:cocina_collection) { FactoryBot.create_for_repository(:collection) }
    let(:existing_collection) { Dor.find(cocina_collection.externalIdentifier) }
    let(:new_title) { 'new coll title' }
    let(:new_abstract) { 'new coll abstract' }
    let(:new_description) do
      {
        title: [{ value: new_title, status: 'primary' }],
        note: [{ value: new_abstract, type: 'summary' }]
      }
    end
    let(:expected_update_body_hash) do
      {
        type: 'http://cocina.sul.stanford.edu/models/collection.jsonld',
        label: new_title,
        version: 1,
        access: { access: 'dark', download: 'none' },
        administrative: { hasAdminPolicy: 'druid:zt570qh4444' },
        description: new_description
      }
    end
    let(:updated_collection) do
      Cocina::Models::Collection.new(externalIdentifier: 'druid:pb873ty1662',
                                     type: Cocina::Models::Vocab.collection,
                                     label: new_title,
                                     version: 1,
                                     access: {},
                                     description: new_description).to_json
    end

    before do
      allow(Dor).to receive(:find).with(existing_collection.pid).and_return(existing_collection)
      stub_request(:post, "#{Settings.dor_services.url}/v1/objects")
        .with(body: JSON.generate(expected_update_body_hash))
        .to_return(status: 200, body: updated_collection, headers: {})
      allow(instance).to receive(:register_model)
      allow(instance).to receive(:sync).and_call_original
      instance.validate(params.merge(apo_pid: apo.pid))
    end

    context 'when metadata_source is label' do
      let(:params) do
        {
          collection_title: new_title,
          collection_abstract: new_abstract,
          collection_rights: 'dark'
        }.with_indifferent_access
      end

      it '#save' do
        instance.save
        expect(instance).not_to have_received(:register_model)
        expect(instance).to have_received(:sync)
        expect(Argo::Indexer).to have_received(:reindex_pid_remotely)
      end

      it 'descMetadata.abstract is updated' do
        expect(instance.model.datastreams['descMetadata'].abstract).to eq []
        instance.save
        expect(instance.model.datastreams['descMetadata'].abstract).to eq [new_abstract]
      end
    end
  end
end

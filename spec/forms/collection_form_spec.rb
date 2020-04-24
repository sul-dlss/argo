# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CollectionForm do
  let(:instance) { described_class.new(Dor::Collection.new) }
  let(:title) { 'collection title' }
  let(:abstract) { 'this is the abstract' }

  let(:apo) { instantiate_fixture('zt570tx3016', Dor::AdminPolicyObject) }
  let(:collection) { instantiate_fixture('pb873ty1662', Dor::Collection) }
  let(:mock_desc_md_ds) { double(Dor::DescMetadataDS, :abstract= => true) }
  let(:workflow_client) { instance_double(Dor::Workflow::Client, create_workflow_by_name: true) }
  let(:created_collection) do
    Cocina::Models::Collection.new(externalIdentifier: 'druid:pb873ty1662',
                                   type: Cocina::Models::Vocab.collection,
                                   label: '',
                                   version: 1,
                                   access: {}).to_json
  end

  before do
    allow(Dor).to receive(:find).with(collection.pid).and_return(collection)
    allow(Dor).to receive(:find).with(apo.pid).and_return(apo)
    allow(Dor::Workflow::Client).to receive(:new).and_return(workflow_client)
    allow(collection).to receive(:descMetadata).and_return(mock_desc_md_ds)
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
      stub_request(:post, 'http://localhost:3003/v1/objects')
        .with(
          body: '{"type":"http://cocina.sul.stanford.edu/models/collection.jsonld",' \
          '"label":"collection title","version":1,"access":{"access":"dark","download":"none"},' \
          '"administrative":{"hasAdminPolicy":"druid:zt570tx3016"}}'
        )
        .to_return(status: 200, body: created_collection, headers: {})
    end

    it 'creates a collection from title/abstract by registering the collection, then adding the abstract' do
      expect(Argo::Indexer).to receive(:reindex_pid_remotely)

      instance.validate(params.merge(apo_pid: apo.pid))
      instance.save

      expect(workflow_client).to have_received(:create_workflow_by_name).with(collection.pid, 'accessionWF', version: '1')
      expect(mock_desc_md_ds).to have_received(:abstract=).with(abstract)
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
      stub_request(:post, 'http://localhost:3003/v1/objects')
        .with(
          body: '{"type":"http://cocina.sul.stanford.edu/models/collection.jsonld",' \
          '"label":":auto","version":1,"access":{"access":"dark","download":"none"},' \
          '"administrative":{"hasAdminPolicy":"druid:zt570tx3016"},' \
          '"identification":{"catalogLinks":[{"catalog":"symphony","catalogRecordId":"99998"}]}}'
        )
        .to_return(status: 200, body: created_collection, headers: {})
    end

    it 'creates a collection from catkey by registering the collection and passing seed_datastream' do
      expect(Argo::Indexer).to receive(:reindex_pid_remotely)

      instance.validate(params.merge(apo_pid: apo.pid))
      instance.save

      expect(workflow_client).to have_received(:create_workflow_by_name)
        .with(collection.pid, 'accessionWF', version: '1')
    end
  end
end

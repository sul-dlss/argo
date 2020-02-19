# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CollectionForm do
  let(:instance) { described_class.new }
  let(:title) { 'collection title' }
  let(:abstract) { 'this is the abstract' }

  let(:apo) { instantiate_fixture('zt570tx3016', Dor::AdminPolicyObject) }
  let(:collection) { instantiate_fixture('pb873ty1662', Dor::Collection) }
  let(:mock_desc_md_ds) { double(Dor::DescMetadataDS, :abstract= => true) }
  let(:objects_client) { instance_double(Dor::Services::Client::Objects, register: { pid: 'druid:pb873ty1662' }) }
  let(:workflow_client) { instance_double(Dor::Workflow::Client, create_workflow_by_name: true) }

  before do
    allow(Dor).to receive(:find).with(collection.pid).and_return(collection)
    allow(Dor).to receive(:find).with(apo.pid).and_return(apo)
    allow(Dor::Services::Client).to receive(:objects).and_return(objects_client)
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

    it 'creates a collection from title/abstract by registering the collection, then adding the abstract' do
      expect(Argo::Indexer).to receive(:reindex_pid_remotely)

      instance.validate(params.merge(apo_pid: apo.pid))
      instance.save

      expect(objects_client).to have_received(:register).with(
        params: {
          label: title,
          object_type: 'collection',
          admin_policy: apo.pid,
          metadata_source: 'label',
          rights: 'dark'
        }
      )
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

    it 'creates a collection from catkey by registering the collection and passing seed_datastream' do
      expect(Argo::Indexer).to receive(:reindex_pid_remotely)

      instance.validate(params.merge(apo_pid: apo.pid))
      instance.save

      expect(objects_client).to have_received(:register).with(
        params: {
          label: ':auto',
          object_type: 'collection',
          admin_policy: apo.pid,
          metadata_source: 'symphony',
          rights: 'dark',
          other_id: 'symphony:99998',
          seed_datastream: ['descMetadata']
        }
      )
      expect(workflow_client).to have_received(:create_workflow_by_name).with(collection.pid, 'accessionWF', version: '1')
    end
  end
end

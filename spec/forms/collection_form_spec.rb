# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CollectionForm do
  let(:instance) { described_class.new }
  let(:title) { 'collection title' }
  let(:abstract) { 'this is the abstract' }
  let(:params) do
    {
      collection_title: title,
      collection_abstract: abstract,
      collection_rights: 'dark'
    }.with_indifferent_access
  end
  let(:apo) { instantiate_fixture('zt570tx3016', Dor::AdminPolicyObject) }
  let(:collection) { instantiate_fixture('pb873ty1662', Dor::Collection) }
  let(:mock_desc_md_ds) { double(Dor::DescMetadataDS) }

  before do
    allow(Dor).to receive(:find).with(collection.pid).and_return(collection)
    allow(collection).to receive(:save)
    allow(Dor).to receive(:find).with(apo.pid).and_return(apo)
  end

  it 'creates a collection from title/abstract by registering the collection, then adding the abstract' do
    expect(mock_desc_md_ds).to receive(:abstract=).with(abstract)
    expect(mock_desc_md_ds).to receive(:ng_xml)
    expect(mock_desc_md_ds).to receive(:content=)
    expect(mock_desc_md_ds).to receive(:save)

    expect(Dor::Services::Client.objects).to receive(:register) do |p|
      expect(p[:params]).to match a_hash_including(
        label: title,
        object_type: 'collection',
        admin_policy: apo.pid,
        metadata_source: 'label',
        rights: 'dark'
      )
      { pid: collection.pid }
    end
    expect(Dor::Config.workflow.client).to receive(:create_workflow_by_name).with(collection.pid, 'accessionWF', version: '1')

    expect(collection).to receive(:update_index)
    expect(collection).to receive(:descMetadata).and_return(mock_desc_md_ds).exactly(4).times

    instance.validate(params.merge(apo_pid: apo.pid))
    instance.save
  end
end

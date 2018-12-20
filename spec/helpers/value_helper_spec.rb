# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ValueHelper do
  let(:document) { SolrDocument.new(document_attributes) }
  let(:args) { { document: document, value: value } }
  let(:blacklight_config) { Blacklight::Configuration.new }
  let(:search_state) { Blacklight::SearchState.new({}, blacklight_config) }
  let(:search_action_path) { '/search_action_path' }
  let(:collection) do
    double('collection', label: 'Boring Fedora Object Label', pid: 'druid:abc123')
  end
  let(:honeybadger) { double(Honeybadger) }

  before do
    allow(helper).to receive(:blacklight_config).and_return blacklight_config
    allow(helper).to receive(:search_state).and_return search_state
    allow(helper).to receive(:search_action_path).and_return search_action_path
  end

  describe '#object_title' do
    it 'fetches the object title from descMetadata and not fedora label' do
      expect(Honeybadger).not_to receive(:notify)
      allow(collection).to receive_message_chain(:descMetadata, :title_info).and_return(['But catz are nice too', 'A different node that will not show'])
      expect(helper.object_title(collection)).to eq 'But catz are nice too'
    end
    it 'notifies HoneyBadger and return Fedora label if there is no title in descMetadata' do
      allow(collection).to receive_message_chain(:descMetadata, :title_info).and_return([''])
      expect(Honeybadger).to receive(:notify).with('No title found in descMetadata for collection druid:abc123')
      expect(helper.object_title(collection)).to eq 'Boring Fedora Object Label'
    end
  end

  describe '#link_to_admin_policy' do
    let(:value) { 'druid:yolo' }
    let(:document_attributes) do
      {
        SolrDocument::FIELD_APO_TITLE => ['Y.O.L.O.'],
        SolrDocument::FIELD_APO_ID => [value]
      }
    end

    it 'creates a link to the admin policies catalog path' do
      expect(helper.link_to_admin_policy(args))
        .to have_css 'a[href="/view/druid:yolo"]', text: 'Y.O.L.O.'
    end
  end

  describe '#link_to_admin_policy_with_objs' do
    let(:value) { 'druid:yolo' }
    let(:document_attributes) do
      {
        SolrDocument::FIELD_APO_TITLE => ['Y.O.L.O.'],
        SolrDocument::FIELD_APO_ID => [value]
      }
    end

    it 'creates a link to the admin policies catalog path with objects' do
      expect(helper.link_to_admin_policy_with_objs(args))
        .to eq('<a href="/view/druid:yolo">Y.O.L.O.</a> (<a href="/search_action_path">All objects with this APO</a>)')
      expect(helper).to have_received(:search_action_path).with('f' => { 'is_governed_by_ssim' => ['info:fedora/druid:yolo'] })
    end
  end

  describe '#links_to_collections' do
    let(:value) do
      ['info:fedora/druid:supercool', 'info:fedora/druid:extracool']
    end
    let(:document_attributes) do
      { SolrDocument::FIELD_COLLECTION_TITLE => ['Super Cool', 'Extra Cool'] }
    end

    it 'creates multiple links delimited by a line break' do
      expect(helper.links_to_collections(args))
        .to have_css 'a[href="/view/druid:supercool"]', text: 'Super Cool'
      expect(helper.links_to_collections(args))
        .to have_css 'a[href="/view/druid:extracool"]', text: 'Extra Cool'
      expect(helper.links_to_collections(args)).to have_css 'br'
    end
  end

  describe '#links_to_collections_with_objs' do
    let(:value) do
      ['info:fedora/druid:supercool']
    end
    let(:document_attributes) do
      { SolrDocument::FIELD_COLLECTION_TITLE => ['Super Cool'] }
    end

    it 'creates link with objs' do
      expect(helper.links_to_collections_with_objs(args))
        .to eq('<a href="/view/druid:supercool">Super Cool</a> (<a href="/search_action_path">All objects in this collection</a>)')
      expect(helper).to have_received(:search_action_path).with('f' => { 'is_member_of_collection_ssim' => ['info:fedora/druid:supercool'] })
    end
  end

  describe '#value_for_wf_error' do
    let(:document_attributes) do
      {
        'wf_error_ssim' => ['accessionWF:technical-metadata:401 Unauthorized']
      }
    end
    let(:args) { { document: document, field: 'wf_error_ssim' } }

    it 'returns a formatted wf error message' do
      expect(helper.value_for_wf_error(args)).to eq 'technical-metadata : 401 Unauthorized'
    end
  end
end

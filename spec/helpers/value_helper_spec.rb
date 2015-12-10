require 'spec_helper'

RSpec.describe ValueHelper do
  let(:document) { SolrDocument.new(document_attributes) }
  let(:args) { { document: document, value: value } }
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
        .to have_css 'a[href="/catalog/druid:yolo"]', text: 'Y.O.L.O.'
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
        .to have_css 'a[href="/catalog/druid:supercool"]', text: 'Super Cool'
      expect(helper.links_to_collections(args))
        .to have_css 'a[href="/catalog/druid:extracool"]', text: 'Extra Cool'
      expect(helper.links_to_collections(args)).to have_css 'br'
    end
  end

  describe 'value_for_date' do
    it 'returns "" for nil' do
      field = 'originInfo_date_created_tesim'
      value = [nil, 'anything_after_first_element_ignored']
      document = SolrDocument.new({ field => value })
      args = { document: document, field: field }
      expect(helper.value_for_date_as_localtime(args)).to eq('')
    end
    it 'returns the value if it cannot parse the date' do
      field = 'originInfo_date_created_tesim'
      value = ['1966', 'anything_after_first_element_ignored']
      document = SolrDocument.new({ field => value })
      args = { document: document, field: field }
      expect(helper.value_for_date_as_localtime(args)).to eq(value.first)
    end
    it 'returns a normalized local time for a valid time stamp' do
      now_utc = Time.zone.now.to_s
      now_loc = Time.zone.parse(now_utc).localtime.strftime '%Y.%m.%d %H:%M%p'
      field = 'originInfo_date_created_tesim'
      value = [now_utc, 'anything_after_first_element_ignored']
      document = SolrDocument.new({ field => value })
      args = { document: document, field: field }
      expect(helper.value_for_date_as_localtime(args)).to eq(now_loc)
    end
  end
end

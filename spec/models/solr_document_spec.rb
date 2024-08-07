# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SolrDocument do
  let(:document) { described_class.new(document_attributes) }
  let(:single_date) { ['2012-04-05T01:00:04.148Z'] }

  describe '#object_type' do
    context 'when field present' do
      let(:document_attributes) do
        { SolrDocument::FIELD_OBJECT_TYPE => ['item', 'other stuff'] }
      end

      it 'returns the first object type' do
        expect(document.object_type).to eq 'item'
      end
    end

    context 'when field not present' do
      let(:document_attributes) { {} }

      it 'returns nil' do
        expect(document.object_type).to be_nil
      end
    end
  end

  describe '#publishable?' do
    subject { document.publishable? }

    let(:document_attributes) do
      { SolrDocument::FIELD_OBJECT_TYPE => [type] }
    end

    context 'when item' do
      let(:type) { 'item' }

      it { is_expected.to be true }
    end

    context 'when collection' do
      let(:type) { 'collection' }

      it { is_expected.to be true }
    end

    context 'when agreement' do
      let(:type) { 'agreement' }

      it { is_expected.to be false }
    end

    context 'when adminPolicy' do
      let(:type) { 'adminPolicy' }

      it { is_expected.to be false }
    end
  end

  describe '#constituents' do
    context 'when field present' do
      let(:constituents) { ['druid:item1', 'druid:item2'] }
      let(:document_attributes) do
        {
          SolrDocument::FIELD_CONSTITUENTS => constituents,
          SolrDocument::FIELD_OBJECT_TYPE => ['item']
        }
      end

      it 'returns the constituents' do
        expect(document.constituents).to eq(constituents)
      end

      it 'knows it is a virtual object' do
        expect(document).to be_virtual_object
      end
    end

    context 'when field not present' do
      let(:document_attributes) do
        {
          SolrDocument::FIELD_OBJECT_TYPE => ['item']
        }
      end

      it 'returns nil' do
        expect(document.constituents).to be_empty
      end

      it 'knows it is not a virtual object' do
        expect(document).not_to be_virtual_object
      end
    end
  end

  describe '#admin_policy?' do
    context 'when object type is an adminPolicy' do
      let(:document_attributes) do
        { SolrDocument::FIELD_OBJECT_TYPE => ['adminPolicy'] }
      end

      it 'checks and returns true' do
        expect(document.admin_policy?).to be true
      end
    end

    context 'when object type is not an adminPolicy' do
      let(:document_attributes) do
        { SolrDocument::FIELD_OBJECT_TYPE => ['item'] }
      end

      it 'checks and returns false' do
        expect(document.admin_policy?).to be false
      end
    end

    context 'when object type is missing' do
      let(:document_attributes) { {} }

      it 'checks and returns false' do
        expect(document.admin_policy?).to be false
      end
    end
  end

  describe '#preservation_size' do
    subject(:preservation_size) { document.preservation_size }

    context 'with data' do
      let(:document_attributes) do
        { SolrDocument::FIELD_PRESERVATION_SIZE => 123_214 }
      end

      it { is_expected.to eq 123_214 }
    end

    context 'without data' do
      let(:document_attributes) { {} }

      it { is_expected.to be_nil }
    end
  end

  describe '#druid' do
    let(:document_attributes) { { id: 'druid:abc123456' } }

    it 'returns the druid' do
      expect(document.druid).to eq 'abc123456'
    end
  end

  context 'when it is embargoed' do
    let(:document_attributes) do
      {
        SolrDocument::FIELD_EMBARGO_STATUS => ['embargoed'],
        SolrDocument::FIELD_EMBARGO_RELEASE_DATE => ['24/02/2259']
      }
    end

    it 'returns embargo status' do
      expect(document).to be_embargoed
      expect(document.embargo_status).to eq 'embargoed'
      expect(document.embargo_release_date).to eq Date.parse('2259-02-24')
    end
  end

  context 'when it is not embargoed' do
    let(:document_attributes) { {} }

    context 'with no field' do
      it 'returns nil' do
        expect(document).not_to be_embargoed
        expect(document.embargo_status).to be_nil
        expect(document.embargo_release_date).to be_nil
      end
    end

    context 'with empty field' do
      let(:document_attributes) do
        {
          SolrDocument::FIELD_EMBARGO_STATUS => nil,
          SolrDocument::FIELD_EMBARGO_RELEASE_DATE => nil
        }
      end

      it 'returns nil' do
        expect(document).not_to be_embargoed
        expect(document.embargo_status).to be_nil
        expect(document.embargo_release_date).to be_nil
      end
    end
  end

  describe '#registered_date' do
    let(:document_attributes) do
      { SolrDocument::FIELD_REGISTERED_DATE => single_date }
    end

    it 'returns date' do
      expect(document.registered_date).to eq Date.parse('2012-04-05T01:00:04.148Z')
    end
  end

  describe '#accessioned_date' do
    let(:document_attributes) do
      { SolrDocument::FIELD_LAST_ACCESSIONED_DATE => single_date }
    end

    it 'returns date' do
      expect(document.accessioned_date).to match_array(single_date)
    end
  end

  describe '#published_date' do
    let(:document_attributes) do
      { SolrDocument::FIELD_LAST_PUBLISHED_DATE => single_date }
    end

    it 'returns date' do
      expect(document.published_date).to match_array(single_date)
    end
  end

  describe '#modified_date' do
    let(:document_attributes) do
      { SolrDocument::FIELD_LAST_MODIFIED_DATE => single_date }
    end

    it 'returns date' do
      expect(document.modified_date).to match_array(single_date)
    end
  end

  describe '#opened_date' do
    let(:document_attributes) do
      { SolrDocument::FIELD_LAST_OPENED_DATE => single_date }
    end

    it 'returns date' do
      expect(document.opened_date).to match_array(single_date)
    end
  end
end

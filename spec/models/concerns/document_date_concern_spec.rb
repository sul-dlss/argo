# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DocumentDateConcern do
  let(:document) { SolrDocument.new(document_attributes) }
  let(:single_date) { ['2012-04-05T01:00:04.148Z'] }

  describe '#registered_date' do
    let(:document_attributes) do
      { SolrDocument::FIELD_REGISTERED_DATE => single_date }
    end

    it 'returns date' do
      expect(document.registered_date).to match_array(single_date)
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

  describe '#submitted_date' do
    let(:document_attributes) do
      { SolrDocument::FIELD_LAST_SUBMITTED_DATE => single_date }
    end

    it 'returns date' do
      expect(document.submitted_date).to match_array(single_date)
    end
  end

  describe '#deposited_date' do
    let(:document_attributes) do
      { SolrDocument::FIELD_LAST_DEPOSITED_DATE => single_date }
    end

    it 'returns date' do
      expect(document.deposited_date).to match_array(single_date)
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

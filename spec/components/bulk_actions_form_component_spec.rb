# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BulkActionsFormComponent, type: :component do
  subject(:instance) { described_class.new }

  let(:blacklight_config) { CatalogController.blacklight_config }
  let(:search_state) { Blacklight::SearchState.new(search_params, blacklight_config) }

  before do
    allow(vc_test_controller).to receive(:current_user).and_return(build(:user))
    allow(subject).to receive(:search_state).and_return(search_state)
  end

  describe '#search_of_druids' do
    context 'when last search is nil' do
      let(:search_params) { nil }

      it 'returns an empty hash' do
        expect(instance.search_of_druids).to eq({})
      end
    end

    context 'when a Blacklight::Search is present' do
      let(:search_params) { { q: 'cool catz', controller: 'catalog' } }

      it 'adds a druids_only param' do
        expect(instance.search_of_druids).to include(:q => 'cool catz', 'druids_only' => true)
      end
    end
  end
end

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BulkActionsFormComponent, type: :component do
  subject(:instance) { described_class.new(form: bulk_action_form, search_params: search_params) }

  let(:bulk_action_form) { BulkActionForm.new(build(:bulk_action), groups: []) }

  before { allow(controller).to receive(:current_user).and_return(build(:user)) }

  describe '#search_of_pids' do
    context "when last search isn't present" do
      let(:search_params) { {} }

      it 'returns an empty string' do
        expect(instance.search_of_pids).to eq ''
      end

      it 'does not render a populate from previous search button' do
        render_inline(subject)
        expect(page).not_to have_button 'Populate with previous search'
      end
    end

    context 'when last search is nil' do
      let(:search_params) { nil }

      it 'returns an empty string' do
        expect(instance.search_of_pids).to eq ''
      end

      it 'does not render a populate from previous search button' do
        render_inline(subject)
        expect(page).not_to have_button 'Populate with previous search'
      end
    end

    context 'when a Blacklight::Search is present' do
      let(:search_params) { { q: 'cool catz' } }

      it 'adds a pids_only param' do
        expect(instance.search_of_pids).to include(q: 'cool catz', 'pids_only' => true)
      end

      it 'renders a populate from previous search button' do
        render_inline(subject)
        expect(page).to have_button 'Populate with previous search'
      end
    end
  end
end

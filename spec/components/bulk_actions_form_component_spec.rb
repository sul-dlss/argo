# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BulkActionsFormComponent, type: :component do
  subject(:instance) { described_class.new(form: nil, last_search: last_search) }

  describe '#search_of_pids' do
    context "when last search isn't present" do
      let(:last_search) { nil }

      it 'returns an empty string' do
        expect(instance.search_of_pids).to eq ''
      end
    end

    context 'when a Blacklight::Search is present' do
      let(:last_search) do
        Search.new.tap do |search|
          search.query_params = { q: 'cool catz' }
        end
      end

      it 'adds a pids_only param' do
        expect(instance.search_of_pids).to include(q: 'cool catz', 'pids_only' => true)
      end
    end
  end
end

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Edit use statement' do
  let(:user) { create(:user) }
  let(:druid) { 'druid:dc243mg0841' }

  let(:turbo_stream_headers) do
    { 'Accept' => "#{Mime[:turbo_stream]},#{Mime[:html]}" }
  end

  before do
    allow(Repository).to receive(:find).and_return(item)
    allow(item).to receive(:save)
    sign_in user, groups: ['sdr:administrator-role']
  end

  describe 'display the form' do
    context 'with an item' do
      let(:item) { build(:item, id: druid) }

      it 'draws the form' do
        get "/items/#{druid}/edit_use_statement", headers: turbo_stream_headers

        expect(response).to be_successful
      end
    end

    context 'with a collection' do
      let(:item) { build(:collection, id: druid) }

      it 'draws the form' do
        get "/items/#{druid}/edit_use_statement", headers: turbo_stream_headers
        expect(response).to be_successful
      end
    end
  end

  describe 'display the show view (after cancel)' do
    context 'with an item' do
      let(:item) { build(:item, id: druid) }

      it 'draws the component' do
        get "/items/#{druid}/show_use_statement", headers: turbo_stream_headers

        expect(response).to be_successful
      end
    end

    context 'with a collection' do
      let(:item) { build(:collection, id: druid) }

      it 'draws the component' do
        get "/items/#{druid}/show_use_statement", headers: turbo_stream_headers
        expect(response).to be_successful
      end
    end
  end
end

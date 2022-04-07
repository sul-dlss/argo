# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Set catkey' do
  let(:user) { create(:user) }
  let(:druid) { 'druid:dc243mg0841' }

  before do
    allow(Repository).to receive(:find).with(druid).and_return(item)
  end

  context 'without manage content access' do
    let(:item) { build(:item, id: druid) }

    before do
      sign_in user
    end

    it 'returns a 403' do
      patch "/items/#{druid}/catkey", params: { catkey: { catkey: '12345' } }

      expect(response.code).to eq('403')
    end
  end

  context 'when they have manage access' do
    before do
      sign_in user, groups: ['sdr:administrator-role']
    end

    describe 'display the form' do
      context 'with an item' do
        let(:item) { build(:item, id: druid) }

        it 'draws the form' do
          get "/items/#{druid}/catkey/edit"

          expect(response).to be_successful
        end
      end

      context 'with a collection that has no existing catkeys' do
        let(:item) { build(:collection, id: druid) }

        it 'draws the form' do
          get "/items/#{druid}/catkey/edit"

          expect(response).to be_successful
        end
      end

      context 'with a collection that has existing catkeys' do
        let(:item) { build(:collection, id: druid, catkeys: ['10448742']) }

        it 'draws the form' do
          get "/items/#{druid}/catkey/edit"

          expect(response).to be_successful
          expect(response.body).to include '10448742'
        end
      end
    end

    describe 'submitting changes' do
      before do
        allow(item).to receive(:save)
        allow(Argo::Indexer).to receive(:reindex_druid_remotely)
      end

      context 'with an item' do
        let(:item) { build(:item, id: druid) }

        it 'updates the catkey, trimming whitespace' do
          patch "/items/#{druid}/catkey", params: { catkey: { catkey: '   12345 ' } }

          expect(item).to have_received(:save)
          expect(Argo::Indexer).to have_received(:reindex_druid_remotely).with(druid)
        end
      end

      context 'with a collection that has no existing catkeys' do
        let(:item) { build(:collection, id: druid) }

        it 'updates the catkey, trimming whitespace' do
          patch "/items/#{druid}/catkey", params: { catkey: { catkey: '   12345 ' } }

          expect(item).to have_received(:save)
          expect(Argo::Indexer).to have_received(:reindex_druid_remotely).with(druid)
        end
      end
    end
  end
end

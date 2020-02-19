# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ContentTypesController, type: :controller do
  before do
    allow(Dor).to receive(:find).with(pid).and_return(item)
    sign_in(user)
  end

  let(:pid) { 'druid:oo201oo0001' }
  let(:item) { Dor::Item.new pid: pid }
  let(:user) { create :user }

  describe 'show' do
    it 'is successful' do
      get :show, params: { item_id: pid }
      expect(response).to be_successful
    end
  end

  describe '#update' do
    before do
      allow(controller).to receive(:current_ability).and_return(ability)
      allow(StateService).to receive(:new).and_return(state_service)
    end

    let(:state_service) { instance_double(StateService, allows_modification?: true) }

    context 'with access' do
      let(:ability) { instance_double(Ability, authorize!: true) }

      it 'is successful' do
        expect(item.contentMetadata).to receive(:set_content_type)
        expect(item).to receive(:save)
        expect(Argo::Indexer).to receive(:reindex_pid_remotely)

        patch :update, params: { item_id: pid, new_content_type: 'media' }
        expect(response).to redirect_to solr_document_path(pid)
      end

      context 'and an invalid content_type' do
        it 'is forbidden' do
          patch :update, params: { item_id: pid, new_content_type: 'frog' }
          expect(response).to be_forbidden
        end
      end

      context 'in a batch process' do
        it 'is successful' do
          expect(item.contentMetadata).to receive(:set_content_type)
          expect(item).to receive(:save)
          expect(Argo::Indexer).not_to receive(:reindex_pid_remotely)

          patch :update, params: { item_id: pid, new_content_type: 'media', bulk: true }
          expect(response).to be_successful
        end
      end
    end
  end
end

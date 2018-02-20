require 'spec_helper'

RSpec.describe ContentTypesController, type: :controller do
  before do
    allow(Dor).to receive(:find).with(pid).and_return(item)
    log_in_as_mock_user(subject)
  end

  let(:pid) { 'druid:oo201oo0001' }
  let(:item) { Dor::Item.new pid: pid }
  let(:user) { FactoryBot.create :user }

  describe 'show' do
    it 'is successful' do
      get :show, params: { item_id: pid }
      expect(response).to be_successful
    end
  end

  describe '#update' do
    before do
      allow(controller).to receive(:current_ability).and_return(ability)
    end

    context 'with access' do
      let(:ability) { instance_double(Ability, authorize!: true) }

      it 'is successful' do
        expect(item.contentMetadata).to receive(:set_content_type)
        expect(item).to receive(:save)
        expect(Dor::SearchService.solr).to receive(:add)
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
          expect(Dor::SearchService.solr).not_to receive(:add)
          patch :update, params: { item_id: pid, new_content_type: 'media', bulk: true }
          expect(response).to be_successful
        end
      end
    end
  end
end

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TagsController, type: :controller do
  before do
    sign_in user
    allow(Dor).to receive(:find).with(pid).and_return(item)
    allow(Argo::Indexer).to receive(:reindex_pid_remotely)
  end

  let(:pid) { 'druid:bc123df4567' }
  let(:item) { Dor::Item.new pid: pid }
  let(:user) { create(:user) }

  describe '#update' do
    context 'when they have manage access' do
      let(:current_tag) { 'Some : Thing' }
      let(:tags_client) do
        instance_double(Dor::Services::Client::AdministrativeTags,
                        list: [current_tag],
                        update: true,
                        destroy: true,
                        create: true)
      end

      before do
        allow(controller).to receive(:authorize!).and_return(true)
        allow(controller).to receive(:tags_client).and_return(tags_client)
      end

      it 'updates tags' do
        post :update, params: { item_id: pid, update: 'true', tag1: 'Some : Thing : Else' }
        expect(tags_client).to have_received(:update).with(current: current_tag, new: 'Some : Thing : Else')
        expect(Argo::Indexer).to have_received(:reindex_pid_remotely)
      end

      it 'deletes tag' do
        post :update, params: { item_id: pid, tag: '1', del: 'true' }
        expect(tags_client).to have_received(:destroy).with(tag: current_tag)
        expect(Argo::Indexer).to have_received(:reindex_pid_remotely)
      end

      it 'adds a tag' do
        post :update, params: { item_id: pid, new_tag1: 'New : Thing', add: 'true' }
        expect(Argo::Indexer).to have_received(:reindex_pid_remotely)
        expect(tags_client).to have_received(:create).with(tags: ['New : Thing'])
      end
    end
  end
end

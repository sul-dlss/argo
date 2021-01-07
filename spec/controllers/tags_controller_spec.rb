# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TagsController, type: :controller do
  let(:user) { create(:user) }

  before do
    sign_in user
  end

  describe '#search' do
    let(:client) { instance_double(Dor::Services::Client::AdministrativeTagSearch, search: '["foo : bar : baz"]') }

    before do
      allow(Dor::Services::Client).to receive(:administrative_tags).and_return(client)
    end

    it 'returns results' do
      get :search, params: { q: 'foo' }
      expect(response.body).to eq '["foo : bar : baz"]'
    end

    context 'when there is a failure' do
      before do
        allow(client).to receive(:search).and_raise(Dor::Services::Client::ConnectionFailed)
      end

      it 'returns results' do
        expect { get :search, params: { q: 'foo' } }.to raise_error Dor::Services::Client::ConnectionFailed
        expect(response.body).to eq '[]'
      end
    end
  end

  describe '#update' do
    let(:pid) { 'druid:bc123df4567' }
    let(:object_client) { instance_double(Dor::Services::Client::Object, find: cocina_model) }
    let(:cocina_model) do
      Cocina::Models.build(
        'label' => 'My Item',
        'version' => 1,
        'type' => Cocina::Models::Vocab.object,
        'externalIdentifier' => pid,
        'access' => {
          'access' => 'world'
        },
        'administrative' => { hasAdminPolicy: 'druid:cg532dg5405' },
        'structural' => {},
        'identification' => {}
      )
    end

    before do
      sign_in user
      allow(Dor::Services::Client).to receive(:object).and_return(object_client)
      allow(Argo::Indexer).to receive(:reindex_pid_remotely)
    end

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

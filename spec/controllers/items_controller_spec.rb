# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ItemsController, type: :controller do
  before do
    allow_any_instance_of(User).to receive(:roles).and_return([])
    sign_in user
    allow(Dor::Services::Client).to receive(:object).with(pid).and_return(object_service)
    allow(Argo::Indexer).to receive(:reindex_pid_remotely)
    allow(StateService).to receive(:new).and_return(state_service)
  end

  let(:pid) { 'druid:bc123df4567' }
  let(:user) { create(:user) }
  let(:state_service) { instance_double(StateService, allows_modification?: true) }
  let(:object_service) { instance_double(Dor::Services::Client::Object, find: cocina) }
  let(:cocina) do
    Cocina::Models.build({
                           'label' => 'My ETD',
                           'version' => 1,
                           'type' => Cocina::Models::ObjectType.object,
                           'externalIdentifier' => pid,
                           'description' => {
                             'title' => [{ 'value' => 'My ETD' }],
                             'purl' => "https://purl.stanford.edu/#{pid.delete_prefix('druid:')}"
                           },
                           'access' => {},
                           'administrative' => { hasAdminPolicy: 'druid:cg532dg5405' },
                           'structural' => {},
                           'identification' => {
                             'catalogLinks' => catalog_links
                           }
                         })
  end
  let(:catalog_links) { [{ catalog: 'symphony', catalogRecordId: '12345' }] }

  describe '#add_collection' do
    let(:cocina_collection) do
      Cocina::Models.build({
                             'label' => 'My ETD',
                             'version' => 1,
                             'type' => Cocina::Models::ObjectType.object,
                             'externalIdentifier' => pid,
                             'description' => {
                               'title' => [{ 'value' => 'My ETD' }],
                               'purl' => "https://purl.stanford.edu/#{pid.delete_prefix('druid:')}"
                             },
                             'access' => {},
                             'administrative' => { 'hasAdminPolicy' => 'druid:cg532dg5405' },
                             'structural' => structural
                           })
    end
    let(:structural) { { 'isMemberOf' => ['druid:gg333xx4444'] } }
    let(:object_service) do
      instance_double(Dor::Services::Client::Object,
                      find: cocina_collection,
                      update: true,
                      collections: [])
    end

    context 'when they have manage access' do
      before do
        allow(controller).to receive(:authorize!).and_return(true)
      end

      context 'when collections already exist' do
        let(:expected) do
          Cocina::Models.build({
                                 'label' => 'My ETD',
                                 'version' => 1,
                                 'type' => Cocina::Models::ObjectType.object,
                                 'externalIdentifier' => pid,
                                 'description' => {
                                   'title' => [{ 'value' => 'My ETD' }],
                                   'purl' => "https://purl.stanford.edu/#{pid.delete_prefix('druid:')}"
                                 },
                                 'access' => {},
                                 'administrative' => { 'hasAdminPolicy' => 'druid:cg532dg5405' },
                                 'structural' => { 'isMemberOf' => ['druid:gg333xx4444', 'druid:bc555gh3434'] }
                               })
        end

        it 'adds a collection' do
          post 'add_collection', params: { id: pid, collection: 'druid:bc555gh3434' }
          expect(object_service).to have_received(:update).with(params: expected)
        end

        context 'when no collection parameter is supplied' do
          it 'does not add a collection' do
            post 'add_collection', params: { id: pid, collection: '' }
            expect(object_service).not_to have_received(:update)
          end
        end
      end

      context 'when the object is not currently in a collection' do
        let(:expected) do
          Cocina::Models.build({
                                 'label' => 'My ETD',
                                 'version' => 1,
                                 'type' => Cocina::Models::ObjectType.object,
                                 'externalIdentifier' => pid,
                                 'description' => {
                                   'title' => [{ 'value' => 'My ETD' }],
                                   'purl' => "https://purl.stanford.edu/#{pid.delete_prefix('druid:')}"
                                 },
                                 'access' => {},
                                 'administrative' => { 'hasAdminPolicy' => 'druid:cg532dg5405' },
                                 'structural' => { 'isMemberOf' => ['druid:bc555gh3434'] }
                               })
        end
        let(:structural) { {} }

        it 'adds a collection' do
          post 'add_collection', params: { id: pid, collection: 'druid:bc555gh3434' }
          expect(object_service).to have_received(:update).with(params: expected)
        end
      end
    end

    context "when they don't have manage access" do
      before do
        allow(controller).to receive(:authorize!).with(:manage_item, cocina_collection).and_raise(CanCan::AccessDenied)
      end

      it 'returns 403' do
        post 'add_collection', params: { id: pid, collection: 'druid:1234' }
        expect(response.code).to eq('403')
        expect(object_service).not_to have_received(:update)
      end
    end
  end

  describe '#remove_collection' do
    let(:cocina) do
      Cocina::Models.build({
                             'label' => 'My ETD',
                             'version' => 1,
                             'type' => Cocina::Models::ObjectType.object,
                             'externalIdentifier' => pid,
                             'description' => {
                               'title' => [{ 'value' => 'My ETD' }],
                               'purl' => "https://purl.stanford.edu/#{pid.delete_prefix('druid:')}"
                             },
                             'access' => {},
                             'administrative' => { 'hasAdminPolicy' => 'druid:cg532dg5405' },
                             'structural' => { 'isMemberOf' => ['druid:gg333xx4444', 'druid:bc555gh3434'] }
                           })
    end

    let(:object_service) do
      instance_double(Dor::Services::Client::Object,
                      find: cocina,
                      update: true,
                      collections: [])
    end

    context 'when they have manage access' do
      before do
        allow(controller).to receive(:authorize!).and_return(true)
      end

      let(:expected) do
        Cocina::Models.build({
                               'label' => 'My ETD',
                               'version' => 1,
                               'type' => Cocina::Models::ObjectType.object,
                               'externalIdentifier' => pid,
                               'description' => {
                                 'title' => [{ 'value' => 'My ETD' }],
                                 'purl' => "https://purl.stanford.edu/#{pid.delete_prefix('druid:')}"
                               },
                               'access' => {},
                               'administrative' => { 'hasAdminPolicy' => 'druid:cg532dg5405' },
                               'structural' => { 'isMemberOf' => ['druid:gg333xx4444'] }
                             })
      end

      it 'removes a collection' do
        post 'remove_collection', params: { id: pid, collection: 'druid:bc555gh3434' }
        expect(object_service).to have_received(:update).with(params: expected)
      end
    end

    context "when they don't have manage access" do
      before do
        allow(controller).to receive(:authorize!).with(:manage_item, cocina).and_raise(CanCan::AccessDenied)
      end

      it 'returns 403' do
        post 'remove_collection', params: { id: pid, collection: 'druid:1234' }
        expect(response.code).to eq('403')
        expect(object_service).not_to have_received(:update)
      end
    end

    context 'when the object is not in any collections' do
      let(:cocina) do
        Cocina::Models.build({
                               'label' => 'My ETD',
                               'version' => 1,
                               'type' => Cocina::Models::ObjectType.object,
                               'externalIdentifier' => pid,
                               'description' => {
                                 'title' => [{ 'value' => 'My ETD' }],
                                 'purl' => "https://purl.stanford.edu/#{pid.delete_prefix('druid:')}"
                               },
                               'access' => {},
                               'administrative' => { 'hasAdminPolicy' => 'druid:cg532dg5405' },
                               'structural' => {}
                             })
      end

      it 'does nothing and does not throw an exception' do
        post 'remove_collection', params: { id: pid, collection: 'druid:1234' }
        expect(object_service).not_to have_received(:update).with(params: cocina)
      end
    end
  end
end

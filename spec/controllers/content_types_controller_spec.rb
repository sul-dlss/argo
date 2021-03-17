# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ContentTypesController, type: :controller do
  before do
    allow(Dor::Services::Client).to receive(:object).and_return(object_client)
    sign_in(user)
  end

  let(:pid) { 'druid:bc123df4567' }
  let(:item) { Dor::Item.new(pid: pid) }
  let(:user) { create :user }
  let(:object_client) { instance_double(Dor::Services::Client::Object, find: cocina_model, update: true) }
  let(:cocina_model) do
    Cocina::Models.build(
      'label' => 'My Item',
      'version' => 1,
      'type' => Cocina::Models::Vocab.image,
      'externalIdentifier' => pid,
      'access' => {
        'access' => 'world'
      },
      'administrative' => { hasAdminPolicy: 'druid:cg532dg5405' },
      'structural' => structural,
      'identification' => {}
    )
  end
  let(:structural) do
    Cocina::Models::DROStructural.new(
      contains: [
        Cocina::Models::FileSet.new(
          externalIdentifier: 'bc123df4567_2',
          type: Cocina::Models::Vocab::Resources.document,
          label: 'document files',
          version: 1,
          structural: Cocina::Models::FileSetStructural.new(
            contains: [
              Cocina::Models::File.new(
                externalIdentifier: 'bc123df4567.pdf',
                type: Cocina::Models::Vocab.file,
                label: 'the PDF',
                filename: 'bc123df4567.pdf',
                version: 1
              )
            ]
          )
        ),
        Cocina::Models::FileSet.new(
          externalIdentifier: 'bc123df4567_2',
          type: Cocina::Models::Vocab::Resources.image,
          label: 'image files',
          version: 1,
          structural: Cocina::Models::FileSetStructural.new(
            contains: [
              Cocina::Models::File.new(
                externalIdentifier: 'bc123df4567.png',
                type: Cocina::Models::Vocab.file,
                label: 'the PNG',
                filename: 'bc123df4567.png',
                version: 1
              )
            ]
          )
        )
      ]
    )
  end

  describe 'show' do
    it 'is successful' do
      get :show, params: { item_id: pid }
      expect(response).to be_successful
    end
  end

  describe '#update' do
    before do
      allow(controller).to receive(:authorize!).and_return(true)
      allow(StateService).to receive(:new).and_return(state_service)
      allow(Argo::Indexer).to receive(:reindex_pid_remotely)
    end

    let(:state_service) { instance_double(StateService, allows_modification?: true) }

    context 'with access' do
      it 'is successful at changing the content type' do
        patch :update, params: { item_id: pid, old_content_type: 'image', new_content_type: 'media' }
        expect(response).to redirect_to solr_document_path(pid)
        expect(object_client).to have_received(:update).with(params: a_cocina_object_with_types(content_type: Cocina::Models::Vocab.media)).once
        expect(Argo::Indexer).to have_received(:reindex_pid_remotely).once
      end

      it 'is successful at changing the resource type' do
        patch :update, params: { item_id: pid, old_resource_type: 'document', new_resource_type: 'file', new_content_type: 'image' }
        expect(response).to redirect_to solr_document_path(pid)
        expect(object_client).to have_received(:update)
          .with(params: a_cocina_object_with_types(resource_types: [Cocina::Models::Vocab::Resources.file, Cocina::Models::Vocab::Resources.image]))
          .once
        expect(Argo::Indexer).to have_received(:reindex_pid_remotely).once
      end

      it 'is successful when effectively a no-op' do
        patch :update, params: { item_id: pid, old_content_type: 'media', new_content_type: 'image', old_resource_type: 'file', new_resource_type: 'document' }
        expect(response).to redirect_to solr_document_path(pid)
        expect(object_client).to have_received(:update)
          .with(
            params: a_cocina_object_with_types(
              content_type: Cocina::Models::Vocab.image,
              resource_types: [Cocina::Models::Vocab::Resources.document, Cocina::Models::Vocab::Resources.image]
            )
          )
          .once
        expect(Argo::Indexer).to have_received(:reindex_pid_remotely).once
      end

      context 'when modification not allowed' do
        let(:state_service) { instance_double(StateService, allows_modification?: false) }

        it 'is forbidden' do
          patch :update, params: { item_id: pid, new_content_type: 'media' }
          expect(response).to be_forbidden
          expect(response.body).to eq('Object cannot be modified in its current state.')
          expect(Argo::Indexer).not_to have_received(:reindex_pid_remotely)
        end
      end

      context 'without structural metadata' do
        let(:structural) { Cocina::Models::DROStructural.new({}) }

        it 'renders an error' do
          patch :update, params: { item_id: pid, new_content_type: 'media' }
          expect(response).to be_forbidden
          expect(response.body).to eq("Object doesn't contain resources to update.")
          expect(Argo::Indexer).not_to have_received(:reindex_pid_remotely)
        end
      end

      context 'with an invalid content_type' do
        it 'is forbidden' do
          patch :update, params: { item_id: pid, new_content_type: 'frog' }
          expect(response).to be_forbidden
          expect(response.body).to eq('Invalid new content type.')
          expect(Argo::Indexer).not_to have_received(:reindex_pid_remotely)
        end
      end

      context 'when a batch process' do
        it 'is successful' do
          patch :update, params: { item_id: pid, new_content_type: 'media', bulk: true }
          expect(response).to be_successful
          expect(Argo::Indexer).not_to have_received(:reindex_pid_remotely)
        end
      end
    end

    context 'without access' do
      before do
        allow(controller).to receive(:authorize!).and_raise(CanCan::AccessDenied)
      end

      it 'is forbidden' do
        patch :update, params: { item_id: pid, new_content_type: 'media' }
        expect(response).to be_forbidden
        expect(response.body).to eq('forbidden')
        expect(Argo::Indexer).not_to have_received(:reindex_pid_remotely)
      end
    end
  end
end

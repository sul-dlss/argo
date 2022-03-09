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

  describe '#purge_object' do
    context "when they don't have manage access" do
      it 'returns 403' do
        allow(controller).to receive(:authorize!).with(:manage_item, cocina).and_raise(CanCan::AccessDenied)
        post 'purge_object', params: { id: pid }
        expect(response.code).to eq('403')
      end
    end

    context 'when they have manage access' do
      let(:client) do
        instance_double(Dor::Workflow::Client,
                        delete_all_workflows: nil,
                        lifecycle: false)
      end

      before do
        allow(Dor::Workflow::Client).to receive(:new).and_return(client)
        allow(controller).to receive(:authorize!).and_return(true)
      end

      context 'when the object has not been submitted' do
        before do
          allow(WorkflowService).to receive(:submitted?).with(druid: pid).and_return(false)
          allow(PurgeService).to receive(:purge)
        end

        it 'deletes the object' do
          delete 'purge_object', params: { id: pid }
          expect(response).to redirect_to root_path
          expect(flash[:notice]).to eq "#{pid} has been purged!"
          expect(PurgeService).to have_received(:purge)
        end
      end

      context 'when the object has been submitted' do
        before do
          allow(WorkflowService).to receive(:submitted?).with(druid: pid).and_return(true)
        end

        it 'blocks purge' do
          delete 'purge_object', params: { id: pid }
          expect(response.code).to eq('400')
          expect(response.body).to eq('Cannot purge an object after it is submitted.')
        end
      end
    end
  end

  describe '#tags_bulk' do
    let(:current_tag) { 'Some : Thing' }
    let(:fake_tags_client) do
      instance_double(Dor::Services::Client::AdministrativeTags,
                      list: [current_tag],
                      update: true,
                      destroy: true,
                      create: true,
                      replace: true)
    end

    before do
      allow(controller).to receive(:authorize!).and_return(true)
      allow(controller).to receive(:tags_client).and_return(fake_tags_client)
      allow(Argo::Indexer).to receive(:reindex_pid_remotely)
    end

    it 'removes an old tag an add a new one' do
      post 'tags_bulk', params: { id: pid, tags: 'New : Thing', bulk: true }
      expect(fake_tags_client).to have_received(:replace).with(tags: ['New : Thing']).once
      expect(Argo::Indexer).to have_received(:reindex_pid_remotely).once
    end

    it 'adds multiple tags' do
      post 'tags_bulk', params: { id: pid, tags: 'Process : Content Type : Book (ltr)	Registered By : labware', bulk: true }
      expect(fake_tags_client).to have_received(:replace)
        .with(tags: ['Process : Content Type : Book (ltr)', 'Registered By : labware'])
        .once
      expect(Argo::Indexer).to have_received(:reindex_pid_remotely).once
    end
  end

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

  describe '#mods' do
    context 'when they have manage access' do
      before do
        allow(controller).to receive(:authorize!).and_return(true)
      end

      let(:object_service) do
        instance_double(Dor::Services::Client::Object, find: cocina, metadata: metadata_service)
      end
      let(:metadata_service) { instance_double(Dor::Services::Client::Metadata, mods: xml) }
      let(:xml) { '<somexml>stuff</somexml>' }

      it 'returns the mods xml for a GET' do
        @request.env['HTTP_ACCEPT'] = 'application/xml'
        get 'mods', params: { id: pid }
        expect(response.body).to eq(xml)
      end
    end

    context "when they don't have manage access" do
      it 'returns 403' do
        allow(controller).to receive(:authorize!).with(:manage_item, cocina).and_raise(CanCan::AccessDenied)
        get 'mods', params: { id: pid }
        expect(response.code).to eq('403')
      end
    end
  end

  describe '#refresh_metadata' do
    context 'when they have manage access' do
      before do
        allow(controller).to receive(:authorize!).and_return(true)
      end

      let(:object_service) { instance_double(Dor::Services::Client::Object, find: cocina, refresh_metadata: true) }

      context 'when the object has no catkey' do
        let(:catalog_links) { [] }

        it 'returns a 400 with an error message' do
          get :refresh_metadata, params: { id: pid }
          expect(response).to have_http_status(:bad_request)
          expect(response.body).to eq 'object must have catkey to refresh descMetadata'
        end
      end

      context 'when a catkey is present' do
        context 'user has permission and object is editable' do
          before do
            allow(Dor::Services::Client).to receive(:object).and_return(object_service)
          end

          it 'redirects with a notice if there is a catkey' do
            get :refresh_metadata, params: { id: pid }
            expect(object_service).to have_received(:refresh_metadata)

            expect(response).to redirect_to(solr_document_path(pid))
            expect(flash[:notice]).to eq "Metadata for #{pid} successfully refreshed from catkey: 12345"
          end
        end

        context "object doesn't allow modification or user doesn't have permission to edit desc metadata" do
          context 'when the user is not allowed to edit desc metadata' do
            before do
              allow(controller).to receive(:authorize!).with(:manage_desc_metadata, cocina).and_raise(CanCan::AccessDenied)
            end

            it 'returns a 403 with an error message' do
              get :refresh_metadata, params: { id: pid }
              expect(response).to have_http_status(:forbidden)
              expect(response.body).to eq 'forbidden'
            end
          end

          context "when the object doesn't allow modification" do
            let(:state_service) { instance_double(StateService, allows_modification?: false) }

            it 'redirects with an error message' do
              get :refresh_metadata, params: { id: pid }
              expect(response).to redirect_to solr_document_path(pid)
              expect(flash[:error]).to eq 'Object cannot be modified in its current state.'
            end
          end
        end
      end
    end
  end
end

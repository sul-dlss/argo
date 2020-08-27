# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ItemsController, type: :controller do
  before do
    allow_any_instance_of(User).to receive(:roles).and_return([])
    sign_in user
    allow(Dor).to receive(:find).with(pid).and_return(item)
    idmd = double
    apo  = double
    idmd_ds_content = '<test-xml/>'
    idmd_ng_xml = instance_double(Nokogiri::XML::Document, to_xml: idmd_ds_content)
    allow(idmd).to receive(:"content_will_change!")
    allow(idmd).to receive(:ng_xml).and_return idmd_ng_xml
    allow(idmd).to receive(:"content=").with(idmd_ds_content)
    allow(apo).to receive(:pid).and_return('druid:apo')
    allow(item).to receive_messages(save: nil, delete: nil,
                                    identityMetadata: idmd,
                                    datastreams: { 'identityMetadata' => idmd, 'events' => Dor::EventsDS.new },
                                    admin_policy_object: apo,
                                    current_version: '3')
    expect(item).not_to receive(:workflows)
    allow(Argo::Indexer).to receive(:reindex_pid_remotely)
    allow(StateService).to receive(:new).and_return(state_service)
  end

  let(:pid) { 'druid:bc123df4567' }
  let(:item) { Dor::Item.new pid: pid }
  let(:user) { create(:user) }
  let(:state_service) { instance_double(StateService, allows_modification?: true) }

  describe '#purl_preview' do
    before do
      allow(Dor::Services::Client).to receive(:object).with(pid).and_return(object_service)
    end

    let(:object_service) { instance_double(Dor::Services::Client::Object, metadata: metadata_service) }
    let(:metadata_service) { instance_double(Dor::Services::Client::Metadata, descriptive: '<xml />') }

    it 'is successful' do
      get :purl_preview, params: { id: pid }
      expect(response).to be_successful
      expect(assigns(:mods_display)).to be_kind_of ModsDisplayObject
    end
  end

  describe '#purge_object' do
    context "when they don't have manage access" do
      it 'returns 403' do
        allow(controller).to receive(:authorize!).with(:manage_item, Dor::Item).and_raise(CanCan::AccessDenied)
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
          allow(controller).to receive(:dor_lifecycle).with(item, 'submitted').and_return(false)
          allow(item).to receive(:delete)
          allow(ActiveFedora.solr.conn).to receive(:delete_by_id)
          allow(ActiveFedora.solr.conn).to receive(:commit)
        end

        it 'deletes the object' do
          delete 'purge_object', params: { id: pid }
          expect(response).to redirect_to root_path
          expect(flash[:notice]).to eq "#{pid} has been purged!"

          expect(client).to have_received(:delete_all_workflows).with(pid: pid)
          expect(item).to have_received(:delete)
          expect(ActiveFedora.solr.conn).to have_received(:delete_by_id).with(pid)
          expect(ActiveFedora.solr.conn).to have_received(:commit)
        end
      end

      context 'when the object has been submitted' do
        before do
          allow(controller).to receive(:dor_lifecycle).with(item, 'submitted').and_return(true)
        end

        it 'blocks purge' do
          delete 'purge_object', params: { id: pid }
          expect(response.code).to eq('400')
          expect(response.body).to eq('Cannot purge an object after it is submitted.')
        end
      end
    end
  end

  describe '#embargo_update' do
    before do
      allow(Dor::Services::Client).to receive(:object).with(pid).and_return(object_service)
    end

    let(:object_service) { instance_double(Dor::Services::Client::Object, embargo: embargo_service) }
    let(:embargo_service) { instance_double(Dor::Services::Client::Embargo, update: true) }

    context "when they don't have manage access" do
      it 'returns 403' do
        allow(controller).to receive(:authorize!).with(:manage_item, Dor::Item).and_raise(CanCan::AccessDenied)
        expect(subject).not_to receive(:save_and_reindex)
        expect(subject).not_to receive(:flush_index)
        post :embargo_update, params: { id: pid, embargo_date: '2100-01-01' }
        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'when they have manage access' do
      before do
        allow(controller).to receive(:authorize!).and_return(true)
      end

      it 'calls Dor::Services::Client::Embargo#update' do
        expect(controller).to receive(:reindex)
        post :embargo_update, params: { id: pid, embargo_date: '2100-01-01' }
        expect(response).to have_http_status(:found) # redirect to catalog page
        expect(embargo_service).to have_received(:update)
      end
      it 'requires a date' do
        expect { post :embargo_update, params: { id: pid } }.to raise_error(ArgumentError)
      end

      context 'when the date is malformed' do
        before do
          allow(embargo_service).to receive(:update).and_raise(Dor::Services::Client::UnexpectedResponse, 'Error: ({"errors":[{"detail":"Invalid date"}]})')
        end

        it 'shows the error' do
          post :embargo_update, params: { id: pid, embargo_date: 'not-a-date' }
          expect(flash[:error]).to eq 'Unable to retrieve the cocina model: Invalid date'
        end
      end
    end
  end

  describe '#source_id' do
    context 'when they have manage access' do
      before do
        allow(controller).to receive(:authorize!).and_return(true)
      end

      it 'updates the source id' do
        expect(item).to receive(:source_id=).with('new:source_id')
        expect(Argo::Indexer).to receive(:reindex_pid_remotely)
        post 'source_id', params: { id: pid, new_id: 'new:source_id' }
      end
    end
  end

  describe '#catkey' do
    context 'without manage content access' do
      it 'returns a 403' do
        allow(controller).to receive(:authorize!).with(:manage_item, Dor::Item).and_raise(CanCan::AccessDenied)
        post 'catkey', params: { id: pid, new_catkey: '12345' }
        expect(response.code).to eq('403')
      end
    end

    context 'when they have manage access' do
      before do
        allow(controller).to receive(:authorize!).and_return(true)
      end

      it 'updates the catkey, trimming whitespace' do
        expect(item).to receive(:catkey=).with('12345')
        expect(Argo::Indexer).to receive(:reindex_pid_remotely)
        post 'catkey', params: { id: pid, new_catkey: '   12345 ' }
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
    context 'when they have manage access' do
      before do
        allow(controller).to receive(:authorize!).and_return(true)
      end

      it 'adds a collection' do
        expect(item).to receive(:add_collection).with('druid:1234')
        post 'add_collection', params: { id: pid, collection: 'druid:1234' }
      end
      context 'when no collection parameter is supplied' do
        it 'does not add a collection' do
          expect(item).not_to receive(:add_collection).with('druid:1234')
          post 'add_collection', params: { id: pid, collection: '' }
        end
      end
    end

    context "when they don't have manage access" do
      it 'returns 403' do
        allow(controller).to receive(:authorize!).with(:manage_item, Dor::Item).and_raise(CanCan::AccessDenied)
        post 'add_collection', params: { id: pid, collection: 'druid:1234' }
        expect(response.code).to eq('403')
      end
    end
  end

  describe '#remove_collection' do
    context 'when they have manage access' do
      before do
        allow(controller).to receive(:authorize!).and_return(true)
      end

      it 'removes a collection' do
        expect(item).to receive(:remove_collection).with('druid:1234')
        post 'remove_collection', params: { id: pid, collection: 'druid:1234' }
      end
    end

    context "when they don't have manage access" do
      it 'returns 403' do
        allow(controller).to receive(:authorize!).with(:manage_item, Dor::Item).and_raise(CanCan::AccessDenied)
        expect(item).not_to receive(:remove_collection)
        post 'remove_collection', params: { id: pid, collection: 'druid:1234' }
        expect(response.code).to eq('403')
      end
    end
  end

  describe '#mods' do
    context 'when they have manage access' do
      before do
        allow(controller).to receive(:authorize!).and_return(true)
      end

      it 'returns the mods xml for a GET' do
        @request.env['HTTP_ACCEPT'] = 'application/xml'
        xml = '<somexml>stuff</somexml>'
        descmd = double
        expect(descmd).to receive(:content).and_return(xml)
        expect(item).to receive(:descMetadata).and_return(descmd)
        get 'mods', params: { id: pid }
        expect(response.body).to eq(xml)
      end
    end

    context "when they don't have manage access" do
      it 'returns 403' do
        allow(controller).to receive(:authorize!).with(:manage_item, Dor::Item).and_raise(CanCan::AccessDenied)
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

      let(:object_service) { instance_double(Dor::Services::Client::Object, refresh_metadata: true) }

      it 'returns a 400 with an error message if there is no catkey' do
        expect(item).to receive(:catkey).and_return('')
        get :refresh_metadata, params: { id: pid }
        expect(response).to have_http_status(:bad_request)
        expect(response.body).to eq 'object must have catkey to refresh descMetadata'
      end

      context 'there is a catkey present' do
        before do
          allow(item).to receive(:catkey).and_return('12345')
        end

        context 'user has permission and object is editable' do
          before do
            allow(Dor::Services::Client).to receive(:object).and_return(object_service)
          end

          it 'redirects with a notice if there is a catkey and the operation is not part of a bulk update' do
            get :refresh_metadata, params: { id: pid }
            expect(object_service).to have_received(:refresh_metadata)

            expect(response).to redirect_to(solr_document_path(pid))
            expect(flash[:notice]).to eq "Metadata for #{item.pid} successfully refreshed from catkey: 12345"
          end

          it 'returns a 200 with a plaintext message if the operation is part of a bulk update' do
            get :refresh_metadata, params: { id: pid, bulk: true }
            expect(object_service).to have_received(:refresh_metadata)

            expect(response).to have_http_status(:ok)
            expect(response.body).to eq 'Refreshed.'
          end
        end

        context "object doesn't allow modification or user doesn't have permission to edit desc metadata" do
          before do
            expect(item).not_to receive(:build_descMetadata_datastream)
            expect(controller).not_to receive(:save_and_reindex)
          end

          it 'returns a 403 with an error message if the user is not allowed to edit desc metadata' do
            expect(controller).to receive(:authorize!).with(:manage_desc_metadata, item).and_raise(CanCan::AccessDenied)
            get :refresh_metadata, params: { id: pid }
            expect(response).to have_http_status(:forbidden)
            expect(response.body).to eq 'forbidden'
          end

          context "when the object doesn't allow modification" do
            let(:state_service) { instance_double(StateService, allows_modification?: false) }

            it 'returns a 400 with an error message' do
              get :refresh_metadata, params: { id: pid }
              expect(response).to have_http_status(:bad_request)
              expect(response.body).to eq 'Object cannot be modified in its current state.'
            end
          end
        end

        context 'Dor::Services::Client::UnexpectedResponse' do
          before do
            allow(Dor::Services::Client).to receive(:object).and_raise(Dor::Services::Client::UnexpectedResponse, 'foo')
          end

          it 'redirects with a user friendly flash error message' do
            get :refresh_metadata, params: { id: pid }

            expect(response).to redirect_to(solr_document_path(pid))
            friendly1 = 'An error occurred while attempting to refresh metadata: foo.'
            friendly2 = 'Please try again or contact the #dlss-infrastructure Slack channel for assistance.'
            expect(flash[:error]).to eq "#{friendly1} #{friendly2}"
          end
        end
      end
    end
  end
end

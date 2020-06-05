# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WorkflowServiceController, type: :controller do
  before do
    sign_in(create(:user))
    allow(Dor::Services::Client).to receive(:object).and_return(object_client)
    allow(Dor::Workflow::Client).to receive(:new).and_return(workflow_client)
  end

  let(:object_client) { instance_double(Dor::Services::Client::Object, version: version_client) }
  let(:workflow_client) { instance_double(Dor::Workflow::Client, active_lifecycle: true) }
  let(:version_client) { instance_double(Dor::Services::Client::ObjectVersion, current: 1) }
  let(:druid) { 'druid:abc:123' }

  describe 'GET closeable' do
    context 'when closeable' do
      context 'when opened and not submitted' do
        before do
          allow(workflow_client)
            .to receive(:active_lifecycle).with(druid: druid, milestone_name: 'opened', version: 1)
                                          .and_return(true)
          allow(workflow_client)
            .to receive(:active_lifecycle).with(druid: druid, milestone_name: 'submitted', version: 1)
                                          .and_return(false)
        end

        context 'when there is no assemblyWF' do
          it 'returns true' do
            expect(workflow_client)
              .to receive(:workflow_status).with(druid: druid, workflow: 'assemblyWF', process: 'accessioning-initiate')
                                           .and_return(nil)
            get :closeable, params: { pid: druid, format: :json }
            expect(workflow_client).to have_received(:active_lifecycle).with(druid: druid, milestone_name: 'opened', version: 1)
            expect(workflow_client).to have_received(:active_lifecycle).with(druid: druid, milestone_name: 'submitted', version: 1)
            expect(assigns(:status)).to eq true
            expect(response.body).to eq 'true'
          end
        end

        context 'when assemblyWF is completed' do
          it 'returns true' do
            expect(workflow_client)
              .to receive(:workflow_status).with(druid: druid, workflow: 'assemblyWF', process: 'accessioning-initiate')
                                           .and_return('completed')

            get :closeable, params: { pid: druid, format: :json }
            expect(workflow_client).to have_received(:active_lifecycle).with(druid: druid, milestone_name: 'opened', version: 1)
            expect(workflow_client).to have_received(:active_lifecycle).with(druid: druid, milestone_name: 'submitted', version: 1)
            expect(assigns(:status)).to eq true
            expect(response.body).to eq 'true'
          end
        end
      end
    end

    context 'when !closeable' do
      context 'when assemblyWF is completed' do
        before do
          allow(workflow_client)
            .to receive(:workflow_status).with(druid: druid, workflow: 'assemblyWF', process: 'accessioning-initiate')
                                         .and_return('completed')
        end

        context 'when !opened' do
          it 'returns false' do
            expect(workflow_client)
              .to receive(:active_lifecycle).with(druid: druid, milestone_name: 'opened', version: 1)
                                            .and_return(false)
            get :closeable, params: { pid: druid, format: :json }
            expect(workflow_client).to have_received(:workflow_status)
            expect(assigns(:status)).to eq false
            expect(response.body).to eq 'false'
          end
        end

        context 'when opened && submitted' do
          it 'returns false' do
            expect(workflow_client)
              .to receive(:active_lifecycle).with(druid: druid, milestone_name: 'opened', version: 1)
                                            .and_return(true)
            expect(workflow_client)
              .to receive(:active_lifecycle).with(druid: druid, milestone_name: 'submitted', version: 1)
                                            .and_return(true)
            get :closeable, params: { pid: druid, format: :json }
            expect(workflow_client).to have_received(:workflow_status)
            expect(assigns(:status)).to eq false
            expect(response.body).to eq 'false'
          end
        end
      end

      context 'when assemblyWF is in progress' do
        it 'returns false' do
          expect(workflow_client)
            .to receive(:workflow_status).with(druid: druid, workflow: 'assemblyWF', process: 'accessioning-initiate')
                                         .and_return('waiting')

          get :closeable, params: { pid: druid, format: :json }
          expect(assigns(:status)).to eq false
          expect(response.body).to eq 'false'
        end
      end
    end
  end

  describe 'GET openable' do
    context 'when not accessioned' do
      it 'returns false' do
        expect(workflow_client)
          .to receive(:lifecycle).with(druid: druid, milestone_name: 'accessioned')
                                 .and_return(false)
        get :openable, params: { pid: druid, format: :json }
        expect(assigns(:status)).to eq false
        expect(response.body).to eq 'false'
      end
    end

    context 'when accessionied' do
      before do
        allow(workflow_client)
          .to receive(:lifecycle).with(druid: druid, milestone_name: 'accessioned')
                                 .and_return(true)
      end

      context 'when submitted' do
        it 'returns false' do
          expect(workflow_client)
            .to receive(:active_lifecycle).with(druid: druid, milestone_name: 'submitted', version: 1)
                                          .and_return(true)
          get :openable, params: { pid: druid, format: :json }
          expect(workflow_client).to have_received(:lifecycle).with(druid: druid, milestone_name: 'accessioned')
          expect(assigns(:status)).to eq false
          expect(response.body).to eq 'false'
        end
      end

      context 'when !submitted' do
        before do
          allow(workflow_client)
            .to receive(:active_lifecycle).with(druid: druid, milestone_name: 'submitted', version: 1)
                                          .and_return(false)
        end

        context 'when opened' do
          it 'returns false' do
            expect(workflow_client)
              .to receive(:active_lifecycle).with(druid: druid, milestone_name: 'opened', version: 1)
                                            .and_return(true)
            get :openable, params: { pid: druid, format: :json }
            expect(workflow_client).to have_received(:lifecycle).with(druid: druid, milestone_name: 'accessioned')
            expect(assigns(:status)).to eq false
            expect(response.body).to eq 'false'
          end
        end

        context 'when !opened' do
          it 'returns true' do
            expect(workflow_client)
              .to receive(:active_lifecycle).with(druid: druid, milestone_name: 'opened', version: 1)
                                            .and_return(false)
            get :openable, params: { pid: druid, format: :json }
            expect(workflow_client).to have_received(:lifecycle).with(druid: druid, milestone_name: 'accessioned')
            expect(assigns(:status)).to eq true
            expect(response.body).to eq 'true'
          end
        end
      end
    end
  end

  describe 'GET published' do
    context 'when published' do
      it 'returns true' do
        expect(workflow_client)
          .to receive(:lifecycle).with(druid: druid, milestone_name: 'published')
                                 .and_return(true)
        get :published, params: { pid: druid, format: :json }
        expect(assigns(:status)).to eq true
        expect(response.body).to eq 'true'
      end
    end

    context 'when not published' do
      it 'returns false' do
        expect(workflow_client)
          .to receive(:lifecycle).with(druid: druid, milestone_name: 'published')
                                 .and_return(false)
        get :published, params: { pid: druid, format: :json }
        expect(assigns(:status)).to eq false
        expect(response.body).to eq 'false'
      end
    end
  end

  describe 'GET submitted' do
    context 'when submitted' do
      it 'returns true' do
        expect(workflow_client)
          .to receive(:lifecycle).with(druid: druid, milestone_name: 'submitted')
                                 .and_return(true)
        get :submitted, params: { pid: druid, format: :json }
        expect(assigns(:status)).to eq true
        expect(response.body).to eq 'true'
      end
    end

    context 'when not submitted' do
      it 'returns false' do
        expect(workflow_client)
          .to receive(:lifecycle).with(druid: druid, milestone_name: 'submitted')
                                 .and_return(false)
        get :submitted, params: { pid: druid, format: :json }
        expect(assigns(:status)).to eq false
        expect(response.body).to eq 'false'
      end
    end
  end

  describe 'GET accessioned' do
    context 'when accessioned' do
      it 'returns true' do
        expect(workflow_client)
          .to receive(:lifecycle).with(druid: druid, milestone_name: 'accessioned')
                                 .and_return(true)
        get :accessioned, params: { pid: druid, format: :json }
        expect(assigns(:status)).to eq true
        expect(response.body).to eq 'true'
      end
    end

    context 'when not accessioned' do
      it 'returns false' do
        expect(workflow_client)
          .to receive(:lifecycle).with(druid: druid, milestone_name: 'accessioned')
                                 .and_return(false)
        get :accessioned, params: { pid: druid, format: :json }
        expect(assigns(:status)).to eq false
        expect(response.body).to eq 'false'
      end
    end
  end
end

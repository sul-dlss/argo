require 'spec_helper'

describe WorkflowServiceController do
  before do
    log_in_as_mock_user(subject)
  end
  let(:druid) { 'druid:abc:123' }
  describe 'GET closeable' do
    context 'when closeable' do
      it 'returns true' do
        expect(Dor::Config.workflow.client)
          .to receive(:get_active_lifecycle).with('dor', druid, 'opened')
          .and_return(true)
        expect(Dor::Config.workflow.client)
          .to receive(:get_active_lifecycle).with('dor', druid, 'submitted')
          .and_return(false)
        get :closeable, params: { pid: druid, format: :json }
        expect(assigns(:status)).to eq true
        expect(response.body).to eq 'true'
      end
    end
    context 'when !closeable' do
      context 'not opened' do
        it 'returns false' do
          expect(Dor::Config.workflow.client)
            .to receive(:get_active_lifecycle).with('dor', druid, 'opened')
            .and_return(false)
          get :closeable, params: { pid: druid, format: :json }
          expect(assigns(:status)).to eq false
          expect(response.body).to eq 'false'
        end
      end
      context 'when opened && is submitted' do
        it 'returns false' do
          expect(Dor::Config.workflow.client)
            .to receive(:get_active_lifecycle).with('dor', druid, 'opened')
            .and_return(true)
          expect(Dor::Config.workflow.client)
            .to receive(:get_active_lifecycle).with('dor', druid, 'submitted')
            .and_return(true)
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
        expect(Dor::Config.workflow.client)
          .to receive(:get_lifecycle).with('dor', druid, 'accessioned')
          .and_return(false)
        get :openable, params: { pid: druid, format: :json }
        expect(assigns(:status)).to eq false
        expect(response.body).to eq 'false'
      end
    end
    context 'when accessioned && submitted' do
      it 'returns false' do
        expect(Dor::Config.workflow.client)
          .to receive(:get_lifecycle).with('dor', druid, 'accessioned')
          .and_return(true)
        expect(Dor::Config.workflow.client)
          .to receive(:get_active_lifecycle).with('dor', druid, 'submitted')
          .and_return(true)
        get :openable, params: { pid: druid, format: :json }
        expect(assigns(:status)).to eq false
        expect(response.body).to eq 'false'
      end
    end
    context 'when accessioned && !submitted && opened' do
      it 'returns false' do
        expect(Dor::Config.workflow.client)
          .to receive(:get_lifecycle).with('dor', druid, 'accessioned')
          .and_return(true)
        expect(Dor::Config.workflow.client)
          .to receive(:get_active_lifecycle).with('dor', druid, 'submitted')
          .and_return(false)
        expect(Dor::Config.workflow.client)
          .to receive(:get_active_lifecycle).with('dor', druid, 'opened')
          .and_return(true)
        get :openable, params: { pid: druid, format: :json }
        expect(assigns(:status)).to eq false
        expect(response.body).to eq 'false'
      end
    end
    context 'when accessioned && !submitted && !opened' do
      it 'returns true' do
        expect(Dor::Config.workflow.client)
          .to receive(:get_lifecycle).with('dor', druid, 'accessioned')
          .and_return(true)
        expect(Dor::Config.workflow.client)
          .to receive(:get_active_lifecycle).with('dor', druid, 'submitted')
          .and_return(false)
        expect(Dor::Config.workflow.client)
          .to receive(:get_active_lifecycle).with('dor', druid, 'opened')
          .and_return(false)
        get :openable, params: { pid: druid, format: :json }
        expect(assigns(:status)).to eq true
        expect(response.body).to eq 'true'
      end
    end
  end
  describe 'GET published' do
    context 'when published' do
      it 'returns true' do
        expect(Dor::Config.workflow.client)
          .to receive(:get_lifecycle).with('dor', druid, 'published')
          .and_return(true)
        get :published, params: { pid: druid, format: :json }
        expect(assigns(:status)).to eq true
        expect(response.body).to eq 'true'
      end
    end
    context 'when not published' do
      it 'returns false' do
        expect(Dor::Config.workflow.client)
          .to receive(:get_lifecycle).with('dor', druid, 'published')
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
        expect(Dor::Config.workflow.client)
          .to receive(:get_lifecycle).with('dor', druid, 'submitted')
          .and_return(true)
        get :submitted, params: { pid: druid, format: :json }
        expect(assigns(:status)).to eq true
        expect(response.body).to eq 'true'
      end
    end
    context 'when not submitted' do
      it 'returns false' do
        expect(Dor::Config.workflow.client)
          .to receive(:get_lifecycle).with('dor', druid, 'submitted')
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
        expect(Dor::Config.workflow.client)
          .to receive(:get_lifecycle).with('dor', druid, 'accessioned')
          .and_return(true)
        get :accessioned, params: { pid: druid, format: :json }
        expect(assigns(:status)).to eq true
        expect(response.body).to eq 'true'
      end
    end
    context 'when not accessioned' do
      it 'returns false' do
        expect(Dor::Config.workflow.client)
          .to receive(:get_lifecycle).with('dor', druid, 'accessioned')
          .and_return(false)
        get :accessioned, params: { pid: druid, format: :json }
        expect(assigns(:status)).to eq false
        expect(response.body).to eq 'false'
      end
    end
  end
end

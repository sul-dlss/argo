# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WorkflowServiceController, type: :controller do
  before do
    sign_in(create(:user))
    allow(Dor::Services::Client).to receive(:object).with(pid).and_return(object_service)
    allow(StateService).to receive(:new).and_return(state_service)
  end

  let(:pid) { 'druid:bc123df4567' }
  let(:user) { create(:user) }
  let(:state_service) { instance_double(StateService) }
  let(:object_service) { instance_double(Dor::Services::Client::Object, find: cocina) }
  let(:cocina) do
    Cocina::Models.build({
                           'label' => 'My ETD',
                           'version' => 1,
                           'type' => Cocina::Models::Vocab.object,
                           'externalIdentifier' => pid,
                           'access' => {},
                           'administrative' => { hasAdminPolicy: 'druid:cg532dg5405' },
                           'structural' => {}
                         })
  end

  describe 'GET published' do
    context 'when published' do
      before { allow(state_service).to receive(:published?).and_return(true) }

      it 'returns true' do
        get :published, params: { id: pid, format: :json }
        expect(assigns(:status)).to be true
        expect(response.body).to eq 'true'
      end
    end

    context 'when not published' do
      before { allow(state_service).to receive(:published?).and_return(false) }

      it 'returns false' do
        get :published, params: { id: pid, format: :json }
        expect(assigns(:status)).to be false
        expect(response.body).to eq 'false'
      end
    end
  end

  describe 'GET lock' do
    context 'when locked' do
      before { allow(state_service).to receive(:object_state).and_return(:lock) }

      it 'returns true' do
        get :lock, params: { id: pid }
        expect(response).to render_template('lock')
      end
    end

    context 'when unlocked' do
      before { allow(state_service).to receive(:object_state).and_return(:unlock) }

      it 'returns false' do
        get :lock, params: { id: pid }
        expect(response).to render_template('unlock')
      end
    end
  end
end

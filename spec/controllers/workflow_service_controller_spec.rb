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

  describe 'GET published' do
    context 'when published' do
      it 'returns true' do
        expect(workflow_client)
          .to receive(:lifecycle).with(druid: druid, milestone_name: 'published')
                                 .and_return(true)
        get :published, params: { id: druid, format: :json }
        expect(assigns(:status)).to eq true
        expect(response.body).to eq 'true'
      end
    end

    context 'when not published' do
      it 'returns false' do
        expect(workflow_client)
          .to receive(:lifecycle).with(druid: druid, milestone_name: 'published')
                                 .and_return(false)
        get :published, params: { id: druid, format: :json }
        expect(assigns(:status)).to eq false
        expect(response.body).to eq 'false'
      end
    end
  end
end

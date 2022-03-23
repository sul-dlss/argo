# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'WorkflowServiceController', type: :request do
  before do
    sign_in(create(:user))
    allow(Dor::Services::Client).to receive(:object).with(druid).and_return(object_service)
    allow(StateService).to receive(:new).and_return(state_service)
  end

  let(:druid) { 'druid:bc123df4567' }
  let(:user) { create(:user) }
  let(:state_service) { instance_double(StateService) }
  let(:object_service) { instance_double(Dor::Services::Client::Object, find: cocina) }
  let(:cocina) do
    Cocina::Models.build({
                           'label' => 'My ETD',
                           'version' => 1,
                           'type' => Cocina::Models::ObjectType.object,
                           'externalIdentifier' => druid,
                           'description' => {
                             'title' => [{ 'value' => 'My ETD' }],
                             'purl' => "https://purl.stanford.edu/#{druid.delete_prefix('druid:')}"
                           },
                           'access' => {},
                           'administrative' => { hasAdminPolicy: 'druid:cg532dg5405' },
                           'structural' => {},
                           'identification' => {}
                         })
  end

  describe 'GET published' do
    context 'when published' do
      before { allow(state_service).to receive(:published?).and_return(true) }

      it 'returns true' do
        get "/workflow_service/#{druid}/published"

        expect(response.body).to eq 'true'
      end
    end

    context 'when not published' do
      before { allow(state_service).to receive(:published?).and_return(false) }

      it 'returns false' do
        get "/workflow_service/#{druid}/published"

        expect(response.body).to eq 'false'
      end
    end
  end

  describe 'GET lock' do
    context 'when locked' do
      before { allow(state_service).to receive(:object_state).and_return(:lock) }

      it 'returns the lock' do
        get "/workflow_service/#{druid}/lock"
        expect(response.body).to include 'Unlock to make changes to this object'
      end
    end

    context 'when unlocked' do
      before { allow(state_service).to receive(:object_state).and_return(:unlock) }

      it 'returns the unlock' do
        get "/workflow_service/#{druid}/lock"
        expect(response.body).to include 'Close Version'
      end
    end
  end
end

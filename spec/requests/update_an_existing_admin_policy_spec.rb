# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Update an existing Admin Policy' do
  let(:pid) { 'druid:bc123df4567' }
  let(:user) { create(:user) }
  let(:object_client) do
    instance_double(Dor::Services::Client::Object, find: cocina_model)
  end
  let(:cocina_model) do
    Cocina::Models.build(
      'label' => 'The item',
      'version' => 1,
      'type' => Cocina::Models::Vocab.admin_policy,
      'externalIdentifier' => pid,
      'description' => {
        'title' => [{ value: 'My APO' }]
      },
      administrative: {
        hasAdminPolicy: 'druid:cg532dg5405',
        registrationWorkflow: ['registrationWF']
      }
    )
  end

  before do
    sign_in user, groups: ['sdr:administrator-role']

    allow(Dor::Services::Client).to receive(:object).and_return(object_client)
  end

  context 'when the parameters are invalid' do
    it 'redraws the form' do
      patch "/apo/#{pid}", params: { apo_form: { title: '' } }
      expect(response).to be_successful
    end
  end
end

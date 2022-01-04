# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Apply APO defaults' do
  let(:pid) { 'druid:bc123df4567' }
  let(:user) { create(:user) }
  let(:object_client) do
    instance_double(Dor::Services::Client::Object, find: cocina_model, apply_admin_policy_defaults: true)
  end
  let(:cocina_model) do
    Cocina::Models.build({
                           'label' => 'The item',
                           'version' => 1,
                           'type' => Cocina::Models::Vocab.object,
                           'externalIdentifier' => pid,
                           'access' => {},
                           'administrative' => { hasAdminPolicy: 'druid:cg532dg5405' },
                           'structural' => {},
                           'identification' => {}
                         })
  end

  before do
    sign_in user
    allow(Argo::Indexer).to receive(:reindex_pid_remotely)
    allow(Dor::Services::Client).to receive(:object).and_return(object_client)
  end

  it 'applies the defaults' do
    post '/items/druid:123/apply_apo_defaults'
    expect(object_client).to have_received(:apply_admin_policy_defaults)
    expect(Argo::Indexer).to have_received(:reindex_pid_remotely).with(pid)
    expect(response).to be_successful
  end
end

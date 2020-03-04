# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Apply APO defaults' do
  let(:item) do
    instance_double(Dor::Item,
                    admin_policy_object: apo,
                    reapply_admin_policy_object_defaults: nil,
                    save: true,
                    pid: 'druid:888')
  end
  let(:apo) { instance_double(Dor::AdminPolicyObject, pid: 'druid:999') }
  let(:user) { create(:user) }

  before do
    sign_in user
    allow(Dor).to receive(:find).and_return(item)
    allow(Argo::Indexer).to receive(:reindex_pid_remotely)
  end

  it 'applies the defaults' do
    post '/items/druid:123/apply_apo_defaults'
    expect(item).to have_received(:reapply_admin_policy_object_defaults)
    expect(Argo::Indexer).to have_received(:reindex_pid_remotely).with('druid:888')
    expect(response).to be_successful
  end
end

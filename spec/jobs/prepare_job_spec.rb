# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PrepareJob, type: :job do
  let(:pids) { ['druid:123', 'druid:456'] }
  let(:groups) { [] }
  let(:user) { instance_double(User, to_s: 'jcoyne85') }
  let(:client) { instance_double(Dor::Services::Client::Object, version: version_client) }
  let(:version_client) { instance_double(Dor::Services::Client::ObjectVersion, open: true) }
  let(:workflow_status) { instance_double(DorObjectWorkflowStatus, can_open_version?: true) }
  let(:bulk_action) do
    create(:bulk_action,
           log_name: 'foo.txt')
  end

  before do
    allow(Dor::Services::Client).to receive(:object).and_return(client)
    allow(DorObjectWorkflowStatus).to receive(:new).and_return(workflow_status)
  end

  after do
    FileUtils.rm('foo.txt')
  end

  it 'opens new versions' do
    described_class.perform_now(bulk_action.id,
                                pids: pids,
                                groups: groups,
                                user: user,
                                prepare: {
                                  'description' => 'Changed dates',
                                  'severity' => 'major'
                                })

    expect(version_client).to have_received(:open)
      .with(vers_md_upd_info: { description: 'Changed dates',
                                opening_user_name: 'jcoyne85',
                                significance: 'major' })
      .twice
  end
end

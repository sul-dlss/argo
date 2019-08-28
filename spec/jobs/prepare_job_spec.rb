# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PrepareJob, type: :job do
  let(:pids) { ['druid:123', 'druid:456'] }
  let(:groups) { [] }
  let(:user) { instance_double(User, to_s: 'jcoyne85') }
  let(:workflow_status) { instance_double(DorObjectWorkflowStatus, can_open_version?: true) }
  let(:bulk_action) { create(:bulk_action, log_name: 'foo.txt') }

  before do
    allow(VersionService).to receive(:open)
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

    expect(VersionService).to have_received(:open).with(identifier: anything,
                                                        vers_md_upd_info: {
                                                          description: 'Changed dates',
                                                          opening_user_name: 'jcoyne85',
                                                          significance: 'major'
                                                        }).twice
  end
end

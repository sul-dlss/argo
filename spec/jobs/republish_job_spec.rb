# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RepublishJob, type: :job do
  let(:pids) { ['druid:123', 'druid:456'] }
  let(:groups) { [] }
  let(:user) { instance_double(User, to_s: 'jcoyne85') }
  let(:bulk_action) { create(:bulk_action, log_name: 'foo.txt') }

  let(:client1) { instance_double(Dor::Services::Client::Object, publish: true) }
  let(:client2) { instance_double(Dor::Services::Client::Object, publish: true) }

  before do
    allow(Dor::Services::Client).to receive(:object).with(pids[0]).and_return(client1)
    allow(Dor::Services::Client).to receive(:object).with(pids[1]).and_return(client2)

    described_class.perform_now(bulk_action.id,
                                pids: pids,
                                groups: groups,
                                user: user)
  end

  after do
    FileUtils.rm('foo.txt')
  end

  it 'publishes objects' do
    expect(client1).to have_received(:publish)
    expect(client2).to have_received(:publish)
  end
end

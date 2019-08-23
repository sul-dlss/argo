# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CloseVersionJob, type: :job do
  let(:pids) { ['druid:123', 'druid:456'] }
  let(:groups) { [] }
  let(:user) { instance_double(User, to_s: 'jcoyne85') }
  let(:client) { instance_double(Dor::Services::Client::Object, version: version_client) }
  let(:version_client) { instance_double(Dor::Services::Client::ObjectVersion, close: true) }
  let(:bulk_action) do
    create(:bulk_action,
           log_name: 'foo.txt')
  end

  before do
    allow(Dor::Services::Client).to receive(:object).and_return(client)
  end

  after do
    FileUtils.rm('foo.txt')
  end

  it 'closes versions' do
    described_class.perform_now(bulk_action.id,
                                pids: pids,
                                groups: groups,
                                user: user)

    expect(version_client).to have_received(:close).twice
  end
end

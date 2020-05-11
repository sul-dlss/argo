# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SetTagsJob, type: :job do
  let(:pids) { ['druid:123	Project : Testing 1', 'druid:456  Project : Testing 2'] }
  let(:druid1) { 'druid:123' }
  let(:tags1) { 'Project : Testing 1' }
  let(:druid2) { 'druid:456' }
  let(:tags2) { 'Project : Testing 2' }
  let(:groups) { [] }
  let(:user) { instance_double(User, to_s: 'jcoyne85') }
  let(:bulk_action) { create(:bulk_action, log_name: 'foo.txt') }

  let(:client1) { instance_double(Dor::Services::Client::Object) }
  let(:client2) { instance_double(Dor::Services::Client::Object) }

  before do
    allow(Dor::Services::Client).to receive(:object).with(druid1).and_return(client1)
    allow(Dor::Services::Client).to receive(:object).with(druid2).and_return(client2)

    described_class.perform_now(bulk_action.id,
                                pids: pids,
                                groups: groups,
                                user: user)
  end

  after do
    FileUtils.rm('foo.txt')
  end

  it 'publishes objects' do
    expect(client1).to have_received(:administrative_tags)
    expect(client2).to have_received(:administrative_tags)
  end
end

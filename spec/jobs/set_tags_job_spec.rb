# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SetTagsJob, type: :job do
  let(:pids) { ["druid:123\tProject : Testing 1", "druid:456\tProject : Testing 2\tTest Tag : Testing 3"] }
  let(:druid1) { 'druid:123' }
  let(:tags1) { ['Project : Testing 1'] }
  let(:druid2) { 'druid:456' }
  let(:tags2) { ['Project : Testing 2', 'Test Tag : Testing 3'] }
  let(:groups) { [] }
  let(:user) { instance_double(User, to_s: 'jcoyne85') }
  let(:bulk_action) { create(:bulk_action, log_name: 'foo.txt') }

  let(:object_client1) { instance_double(Dor::Services::Client::Object, administrative_tags: tags_client1) }
  let(:object_client2) { instance_double(Dor::Services::Client::Object, administrative_tags: tags_client2) }
  let(:tags_client1) { instance_double(Dor::Services::Client::AdministrativeTags) }
  let(:tags_client2) { instance_double(Dor::Services::Client::AdministrativeTags) }

  before do
    allow(Dor::Services::Client).to receive(:object).with(druid1).and_return(object_client1)
    allow(Dor::Services::Client).to receive(:object).with(druid2).and_return(object_client2)
    allow(tags_client1).to receive(:replace).with(tags: tags1)
    allow(tags_client2).to receive(:replace).with(tags: tags2)
    allow(Argo::Indexer).to receive(:reindex_pid_remotely)

    described_class.perform_now(bulk_action.id,
                                pids: pids,
                                groups: groups,
                                user: user)
  end

  after do
    FileUtils.rm('foo.txt')
  end

  it 'adds tags to pids in list' do
    expect(tags_client1).to have_received(:replace).with(tags: tags1)
    expect(tags_client2).to have_received(:replace).with(tags: tags2)
    expect(Argo::Indexer).to have_received(:reindex_pid_remotely).twice
  end
end

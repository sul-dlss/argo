# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ExportTagsJob do
  subject(:job) { described_class.new(bulk_action.id, druids: [druid]) }

  let(:druid) { 'druid:bc123df4567' }

  let(:bulk_action) { create(:bulk_action) }
  let(:csv_path) { File.join(bulk_action.output_directory, Settings.export_tags_job.csv_filename) }
  let(:log) { StringIO.new }

  let(:object_client) { instance_double(Dor::Services::Client::Object, administrative_tags: tags_client) }
  let(:tags_client) { instance_double(Dor::Services::Client::AdministrativeTags, list: tags) }
  let(:tags) { ['Project : Testing 2', 'Test Tag : Testing 3'] }

  before do
    allow_any_instance_of(BulkAction).to receive(:open_log_file).and_return(log) # rubocop:disable RSpec/AnyInstance
    allow(Dor::Services::Client).to receive(:object).with(druid).and_return(object_client)
  end

  after do
    FileUtils.rm_f(csv_path)
  end

  it 'performs the job' do
    job.perform_now

    expect(Dor::Services::Client).to have_received(:object).with(druid)
    expect(tags_client).to have_received(:list).once

    expect(File).to exist(csv_path)
    output = CSV.read(csv_path)
    expect(output.first.to_csv).to eq "druid:bc123df4567,Project : Testing 2,Test Tag : Testing 3\n"

    expect(bulk_action.reload.druid_count_total).to eq(1)
    expect(bulk_action.druid_count_success).to eq(1)
    expect(bulk_action.druid_count_fail).to eq(0)
  end
end

require 'spec_helper'

RSpec.describe BulkAction do
  describe '#file' do
    it 'returns a full path filename' do
      @bulk_action = BulkAction.create(action_type: 'GenericJob', pids: '')
      expect(@bulk_action.file('hello_world.txt'))
        .to eq "/tmp/bulk_jobs/GenericJob_#{@bulk_action.id}/hello_world.txt"
    end
  end
  describe 'triggers after_create callbacks' do
    before(:each) do
      @bulk_action = BulkAction.create(action_type: 'GenericJob', pids: '')
    end
    it '#create_output_directory' do
      expect(@bulk_action).to receive(:create_output_directory)
      @bulk_action.run_callbacks(:create) { true }
    end
    it '#create_log_file' do
      expect(@bulk_action).to receive(:create_log_file)
      @bulk_action.run_callbacks(:create) { true }
    end
    it '#process_bulk_action_type' do
      expect(@bulk_action).to receive(:process_bulk_action_type)
      @bulk_action.run_callbacks(:create) { true }
    end
  end
  ##
  # This is testing the completion of private methods
  describe 'directory and file creation' do
    before(:each) do
      @bulk_action = BulkAction.create(action_type: 'GenericJob', pids: '')
      @bulk_action.run_callbacks(:create) { true }
    end
    let(:directory) do
      File.join(
        Settings.BULK_METADATA.DIRECTORY,
        "#{@bulk_action.action_type}_#{@bulk_action.id}"
      )
    end
    it 'output_directory exists' do
      expect(Dir.exist?(directory)).to be true
    end
    it 'output_file exists' do
      expect(File.exist?(File.join(Settings.BULK_METADATA.LOG)))
    end
  end
  it 'makes sure BulkAction job was kicked off' do
    @bulk_action = BulkAction.create(action_type: 'GenericJob', pids: 'a b c')
    expect(GenericJob).to receive(:perform_later)
      .with(
        %w(a b c),
        @bulk_action.id,
        Settings.BULK_METADATA.DIRECTORY +
          "#{@bulk_action.action_type}_#{@bulk_action.id}"
      )
    @bulk_action.run_callbacks(:create) { true }
  end
end

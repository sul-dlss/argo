# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkAction do
  describe 'valid action_types' do
    it 'does not allow nonspecified action_types' do
      expect(described_class.create(action_type: 'YoloJob').save).to be false
    end
  end

  describe '#file' do
    it 'returns the filename with path' do
      @bulk_action = described_class.create(action_type: 'GenericJob', pids: '')
      expect(@bulk_action.file('hello_world.txt'))
        .to eq "#{Settings.BULK_METADATA.DIRECTORY}GenericJob_#{@bulk_action.id}/hello_world.txt"
    end
  end

  describe 'triggers after_create callbacks' do
    before do
      @bulk_action = described_class.create(action_type: 'GenericJob', pids: '')
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
    before do
      @bulk_action = described_class.create(action_type: 'GenericJob', pids: '')
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

  it 'makes sure BulkAction job was kicked off, and prepends druid: to all pids' do
    @bulk_action = described_class.create(
      action_type: 'GenericJob', pids: 'a b c', manage_release: {}
    )
    expect(GenericJob).to receive(:perform_later)
      .with(
        @bulk_action.id,
        hash_including(
          pids: %w(druid:a druid:b druid:c),
          output_directory: Settings.BULK_METADATA.DIRECTORY +
            "#{@bulk_action.action_type}_#{@bulk_action.id}",
          manage_release: {}
        )
      )
    @bulk_action.run_callbacks(:create) { true }
  end

  it 'makes sure BulkAction job was kicked off, and does not prepend druid if it exists' do
    @bulk_action = described_class.create(
      action_type: 'GenericJob', pids: 'druid:abcdef druid:q124567 druid:wz34566', manage_release: {}
    )
    expect(GenericJob).to receive(:perform_later)
      .with(@bulk_action.id, hash_including(pids: %w(druid:abcdef druid:q124567 druid:wz34566)))
    @bulk_action.run_callbacks(:create) { true }
  end

  describe 'before_destroy callbacks' do
    it 'calls #remove_output_directory' do
      @bulk_action = described_class.create(action_type: 'GenericJob', pids: '')
      expect(@bulk_action).to receive(:remove_output_directory)
      @bulk_action.run_callbacks(:destroy) { true }
    end
  end

  describe '#remove_output_directory' do
    let(:directory) do
      File.join(
        Settings.BULK_METADATA.DIRECTORY,
        "#{@bulk_action.action_type}_#{@bulk_action.id}"
      )
    end

    it 'cleans up output directory' do
      @bulk_action = described_class.create(action_type: 'GenericJob', pids: '')
      @bulk_action.run_callbacks(:create) { true }
      expect(Dir.exist?(directory)).to be true
      @bulk_action.destroy
      expect(Dir.exist?(directory)).to be false
    end
  end
end

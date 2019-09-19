# frozen_string_literal: true

require 'rails_helper'

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
        .to eq "#{Settings.bulk_metadata.directory}GenericJob_#{@bulk_action.id}/hello_world.txt"
    end
  end

  ##
  # This is testing the completion of private methods

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
        Settings.bulk_metadata.directory,
        "#{bulk_action.action_type}_#{bulk_action.id}"
      )
    end
    let(:bulk_action) { described_class.create(action_type: 'GenericJob', pids: '') }

    before do
      FileUtils.mkdir_p(directory)
    end

    it 'cleans up output directory' do
      expect(Dir.exist?(directory)).to be true
      bulk_action.destroy
      expect(Dir.exist?(directory)).to be false
    end
  end
end

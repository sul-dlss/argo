# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BulkActionPersister do
  let(:bulk_action) do
    BulkAction.create(
      action_type: 'GenericJob',
      pids: 'a b c',
      manage_release: {}
    )
  end

  it 'makes sure BulkAction job was kicked off' do
    expect(GenericJob).to receive(:perform_later)
      .with(
        bulk_action.id,
        hash_including(
          pids: %w(a b c),
          output_directory: Settings.bulk_metadata.directory +
            "#{bulk_action.action_type}_#{bulk_action.id}",
          manage_release: {}
        )
      )
    described_class.persist(bulk_action)
  end

  describe 'all the steps are called' do
    let(:service) { described_class.new(bulk_action) }

    it '#create_output_directory' do
      expect(service).to receive(:create_output_directory)
      service.persist
    end

    it '#create_log_file' do
      expect(service).to receive(:create_log_file)
      service.persist
    end

    it '#process_bulk_action_type' do
      expect(service).to receive(:process_bulk_action_type)
      service.persist
    end
  end

  describe 'directory and file creation' do
    let(:service) { described_class.new(bulk_action) }

    let(:directory) do
      File.join(
        Settings.bulk_metadata.directory,
        "#{bulk_action.action_type}_#{bulk_action.id}"
      )
    end

    before do
      service.persist
    end

    it 'output_directory exists' do
      expect(Dir).to exist(bulk_action.output_directory)
    end

    it 'output_file exists' do
      expect(File).to exist(bulk_action.file(Settings.bulk_metadata.log))
    end
  end

  describe '#job_params' do
    subject { service.send(:job_params) }

    let(:service) { described_class.new(bulk_action) }

    context 'for a prepare job' do
      let(:bulk_action) do
        BulkAction.create(
          action_type: 'PrepareJob',
          pids: 'a b c',
          prepare: { 'significance' => 'minor', 'description' => 'change the data' }
        )
      end

      it { is_expected.to include(prepare: { 'description' => 'change the data', 'significance' => 'minor' }) }
    end

    context 'for a create virtual objects job' do
      let(:bulk_action) do
        BulkAction.create(
          action_type: 'CreateVirtualObjectsJob',
          pids: 'a b c',
          create_virtual_objects: { csv_file: fake_io }
        )
      end
      let(:fake_io) { double('IO', path: '/path/unused/in/spec') }

      before do
        allow(File).to receive(:read).and_return("parent1,child1,child2\nparent2,child3,child4,child5")
      end

      it { is_expected.to include(create_virtual_objects: "parent1,child1,child2\nparent2,child3,child4,child5") }
    end
  end
end

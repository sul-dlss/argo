# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Argo::Indexer do
  describe '#reindex_pid_list_with_profiling' do
    it "logs what it's about to do, use the profiler, and print profiling results" do
      mock_index_logger = double(Logger)
      mock_profiler = double(Argo::Profiler)

      expect(described_class).to receive(:default_index_logger).and_return(mock_index_logger)
      expect(mock_index_logger).to receive(:info)
      expect(Argo::Profiler).to receive(:new).and_return(mock_profiler)
      expect(mock_profiler).to receive(:prof)
      expect(mock_profiler).to receive(:print_results_call_tree)

      described_class.reindex_pid_list_with_profiling []
    end
  end
end

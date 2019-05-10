# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Argo::Indexer do
  let(:mock_pid) { 'druid:aa111bb2222' }
  let(:mock_default_logger) { double(Logger) }

  describe '#reindex_pid_remotely' do
    before do
      allow(Rails).to receive(:logger).and_return(mock_default_logger)
    end

    it 'calls a remote service to reindex' do
      expect(RestClient).to receive(:post).and_return(double)
      expect(mock_default_logger).to receive(:info).with(/successfully updated index for druid:/)
      described_class.reindex_pid_remotely(mock_pid)
    end

    it 'calls a remote service to reindex even without a druid: prefix' do
      expect(RestClient).to receive(:post).and_return(double)
      expect(mock_default_logger).to receive(:info).with(/successfully updated index for druid:/)
      described_class.reindex_pid_remotely('aa111bb2222')
    end

    it 'raises a ReindexRemotelyError exception in cases of predictable failures' do
      expect(RestClient).to receive(:post).exactly(3).and_raise(RestClient::Exception.new(double))
      expect(mock_default_logger).to receive(:error).with(/failed to reindex/)
      expect { described_class.reindex_pid_remotely(mock_pid) }.to raise_error(Argo::Exceptions::ReindexError)
    end

    it 'raises a ReindexRemotelyError exception in cases of remote host is down' do
      expect(RestClient).to receive(:post).exactly(3).and_raise(Errno::ECONNREFUSED)
      expect(mock_default_logger).to receive(:error).with(/failed to reindex/)
      expect { described_class.reindex_pid_remotely(mock_pid) }.to raise_error(Argo::Exceptions::ReindexError)
    end

    it 'raises other exceptions in cases of unpredictable failures' do
      expect(RestClient).to receive(:post).and_raise(RuntimeError.new)
      expect(mock_default_logger).to receive(:error).with(/failed to reindex/)
      expect { described_class.reindex_pid_remotely(mock_pid) }.to raise_error(RuntimeError)
    end
  end
end

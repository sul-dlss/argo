# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Argo::Indexer do
  let(:mock_druid) { 'druid:aa111bb2222' }
  let(:mock_default_logger) { double(Logger) }

  describe '#reindex_druid_remotely' do
    before do
      allow(Rails).to receive(:logger).and_return(mock_default_logger)
    end

    it 'calls a remote service to reindex' do
      stub_request(:post, "#{Settings.dor_indexing_url}/reindex/druid:aa111bb2222")
        .to_return(status: 200, body: '', headers: {})
      expect(mock_default_logger).to receive(:info).with(/successfully updated index for druid:/)
      described_class.reindex_druid_remotely(mock_druid)
    end

    it 'calls a remote service to reindex even without a druid: prefix' do
      stub_request(:post, "#{Settings.dor_indexing_url}/reindex/druid:aa111bb2222")
        .to_return(status: 200, body: '', headers: {})
      expect(mock_default_logger).to receive(:info).with(/successfully updated index for druid:/)
      described_class.reindex_druid_remotely('aa111bb2222')
    end

    it 'raises a ReindexRemotelyError exception in cases of remote host is down' do
      expect(Faraday).to receive(:post).at_least(3).times.and_raise(Errno::ECONNREFUSED)
      expect(mock_default_logger).to receive(:error).at_least(:once).with(/failed to reindex/)
      expect { described_class.reindex_druid_remotely(mock_druid) }.to raise_error(Argo::Exceptions::ReindexError)
    end

    it 'raises other exceptions in cases of unpredictable failures' do
      expect(Faraday).to receive(:post).and_raise(RuntimeError.new)
      expect(mock_default_logger).to receive(:error).with(/failed to reindex/)
      expect { described_class.reindex_druid_remotely(mock_druid) }.to raise_error(RuntimeError)
    end
  end
end

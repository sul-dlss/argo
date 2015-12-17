require 'spec_helper'

RSpec.describe Argo::Indexer do
  describe '#generate_index_logger' do
    before :each do
      @test_log_file = 'tmp/indexer.log.test'
      @mock_entry_id = 'unique_request_id'
      @mock_log_msg = 'something noteworthy'
    end

    after :each do
      File.delete @test_log_file if File.exist? @test_log_file
    end

    it 'should call entry_id_block and include the result in the logging statement' do
      expect(Settings.INDEXER).to receive(:LOG).and_return(@test_log_file)

      is_entry_id_block_executed = false
      test_index_logger = Argo::Indexer.generate_index_logger do
        is_entry_id_block_executed = true
        @mock_entry_id
      end
      test_index_logger.info @mock_log_msg

      last_log_line = open(@test_log_file).read.split("\n")[-1]
      expect(last_log_line).to match(/\[#{@mock_entry_id}\] \[.*\] #{@mock_log_msg}$/)
      expect(is_entry_id_block_executed).to eq(true)
    end

    it 'should log the default entry_id if entry_id_block is nil' do
      expect(Settings.INDEXER).to receive(:LOG).and_return(@test_log_file)
      test_index_logger = Argo::Indexer.generate_index_logger
      test_index_logger.info @mock_log_msg
      last_log_line = open(@test_log_file).read.split("\n")[-1]
      expect(last_log_line).to match(/\[---\] \[.*\] #{@mock_log_msg}$/)
    end

    it 'should log the default entry_id if entry_id_block throws a StandardError' do
      expect(Settings.INDEXER).to receive(:LOG).and_return(@test_log_file)

      test_index_logger = Argo::Indexer.generate_index_logger do
        raise ZeroDivisionError.new 'whoops'
      end
      test_index_logger.info @mock_log_msg

      last_log_line = open(@test_log_file).read.split("\n")[-1]
      expect(last_log_line).to match(/\[---\] \[.*\] #{@mock_log_msg}$/)
    end

    it "should not trap the exception if it's not StandardError" do
      expect(Settings.INDEXER).to receive(:LOG).and_return(@test_log_file)
      stack_overflow_ex = SystemStackError.new 'really? here?'
      test_index_logger = Argo::Indexer.generate_index_logger { raise stack_overflow_ex }
      expect { test_index_logger.info @mock_log_msg }.to raise_error(stack_overflow_ex)
    end
  end

  describe '#default_index_logger' do
    it 'should call generate_index_logger, and memoize the result' do
      mock_index_logger = double(Logger)
      expect(Argo::Indexer).to receive(:generate_index_logger).once.and_return(mock_index_logger)
      expect(Argo::Indexer.default_index_logger).to eq(mock_index_logger)
      expect(Argo::Indexer.default_index_logger).to eq(mock_index_logger)
    end
  end

  describe '#reindex_pid_list_with_profiling' do
    it "should log what it's about to do, use the profiler, and print profiling results" do
      # TODO: it'd be nice to do more thorough parameter checking, and to check what's in the block received by profiler.prof
      mock_index_logger = double(Logger)
      mock_profiler = double(Argo::Profiler)

      expect(Argo::Indexer).to receive(:default_index_logger).and_return(mock_index_logger)
      expect(mock_index_logger).to receive(:info)
      expect(Argo::Profiler).to receive(:new).and_return(mock_profiler)
      expect(mock_profiler).to receive(:prof)
      expect(mock_profiler).to receive(:print_results_call_tree)

      Argo::Indexer.reindex_pid_list_with_profiling []
    end
  end

  describe '#reindex_pid_list' do
    before :each do
      @mock_solr_conn = double(ActiveFedora.solr.conn)
    end

    it 'should reindex the pids and not commit by default' do
      pids = [1..10].map(&:to_s)
      pids.each { |pid| expect(Argo::Indexer).to receive(:reindex_pid).with(pid, nil, false) }
      expect(@mock_solr_conn).to_not receive(:commit)
      Argo::Indexer.reindex_pid_list pids
    end

    it 'should reindex the pids and commit if should_commit is true' do
      pids = [1..10].map(&:to_s)
      pids.each { |pid| expect(Argo::Indexer).to receive(:reindex_pid).with(pid, nil, false) }
      expect(ActiveFedora.solr).to receive(:conn).and_return(@mock_solr_conn)
      expect(@mock_solr_conn).to receive(:commit)
      Argo::Indexer.reindex_pid_list pids, true
    end

    it 'should proceed despite individual indexing failures' do
      pids = [1..10].map(&:to_s)
      expect(Argo::Indexer).to receive(:reindex_pid).with(pids[0], nil, false)
      pids[1..-1].each { |pid| expect(Argo::Indexer).to receive(:reindex_pid).with(pid, nil, false) }
      expect(ActiveFedora.solr).to receive(:conn).and_return(@mock_solr_conn)
      expect(@mock_solr_conn).to receive(:commit)
      Argo::Indexer.reindex_pid_list pids, true
    end
  end

  describe '#reindex_object' do
    before :each do
      @mock_pid = 'unique_id'
      @mock_obj = double(Dor::Item)
      @mock_solr_doc  = {id: @mock_pid, text_field_tesim: 'a field to be searched'}
    end

    it 'should reindex the object via Dor::SearchService' do
      expect(@mock_obj).to receive(:to_solr).and_return(@mock_solr_doc)
      expect(Dor::SearchService.solr).to receive(:add).with(hash_including(:id => @mock_pid))
      ret_val = Argo::Indexer.reindex_object @mock_obj
      expect(ret_val).to eq(@mock_solr_doc)
    end
  end

  describe '#reindex_pid' do
    before :each do
      @mock_pid = 'unique_id'
      @mock_default_logger = double(Logger)
      @mock_obj = double(Dor::Item)
      @mock_solr_doc  = {id: @mock_pid, text_field_tesim: 'a field to be searched'}
      allow(Argo::Indexer).to receive(:default_index_logger).and_return(@mock_default_logger)
    end

    it 'should reindex the object via Argo::Indexer.reindex_pid and log success' do
      expect(Dor).to receive(:load_instance).with(@mock_pid).and_return(@mock_obj)
      expect(Argo::Indexer).to receive(:reindex_object).with(@mock_obj).and_return(@mock_solr_doc)
      expect(@mock_default_logger).to receive(:info).with("updated index for #{@mock_pid}")
      ret_val = Argo::Indexer.reindex_pid @mock_pid
      expect(ret_val).to eq(@mock_solr_doc)
    end

    it 'should log the right thing if an object is not found, then re-raise the exception by default' do
      expect(Dor).to receive(:load_instance).with(@mock_pid).and_raise(ActiveFedora::ObjectNotFoundError)
      expect(@mock_default_logger).to receive(:warn).with("failed to update index for #{@mock_pid}, object not found in Fedora")
      expect { Argo::Indexer.reindex_pid(@mock_pid) }.to raise_error(ActiveFedora::ObjectNotFoundError)
    end

    it 'should log the right thing if an object is not found, but swallow the exception when should_raise_errors is false' do
      expect(Dor).to receive(:load_instance).with(@mock_pid).and_raise(ActiveFedora::ObjectNotFoundError)
      expect(@mock_default_logger).to receive(:warn).with("failed to update index for #{@mock_pid}, object not found in Fedora")
      expect { Argo::Indexer.reindex_pid(@mock_pid, nil, false) }.to_not raise_error
    end

    it "should log the right thing if there's an unexpected error, then re-raise the exception by default" do
      unexpected_err = ZeroDivisionError.new "how'd that happen?"
      expect(Dor).to receive(:load_instance).with(@mock_pid).and_raise(unexpected_err)
      expect(@mock_default_logger).to receive(:warn).with(start_with("failed to update index for #{@mock_pid}, unexpected StandardError, see main app log: ["))
      expect { Argo::Indexer.reindex_pid(@mock_pid) }.to raise_error(unexpected_err)
    end

    it "should log the right thing if there's an unexpected Exception that's not StandardError, then re-raise the exception, even when should_raise_errors is false" do
      stack_overflow_ex = SystemStackError.new "didn't see that one coming... maybe you shouldn't have self-referential collections?"
      expect(Dor).to receive(:load_instance).with(@mock_pid).and_raise(stack_overflow_ex)
      expect(@mock_default_logger).to receive(:error).with(start_with("failed to update index for #{@mock_pid}, unexpected Exception, see main app log: ["))
      expect { Argo::Indexer.reindex_pid(@mock_pid, nil, false) }.to raise_error(stack_overflow_ex)
    end
  end
end

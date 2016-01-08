module Argo
  class Indexer
    ##
    # Returns a Logger instance for recording info about indexing attempts
    # @yield attempt to execute 'entry_id_block' and use the result as an extra identifier for the log
    #   entry.  a placeholder will be used otherwise. 'request.uuid' might be useful in a Rails app.
    def self.generate_index_logger(&entry_id_block)
      index_logger = Logger.new(Settings.INDEXER.LOG, Settings.INDEXER.LOG_ROTATION_INTERVAL)
      index_logger.formatter = proc do |severity, datetime, progname, msg|
        date_format_str = Argo::Config.date_format_str
        entry_id = begin entry_id_block.call rescue '---' end
        "[#{entry_id}] [#{datetime.utc.strftime(date_format_str)}] #{msg}\n"
      end
      index_logger
    end

    # get a memoized index logger instance
    @@default_index_logger = nil
    def self.default_index_logger
      @@default_index_logger ||= generate_index_logger
    end

    # takes a Dor object and indexes it to solr.  doesn't commit automatically.
    def self.reindex_object(obj)
      solr_doc = obj.to_solr
      Dor::SearchService.solr.add(solr_doc)
      solr_doc
    end

    # retrieves a single Dor object by pid, indexes the object to solr, does some logging
    # (will use a defualt logger if one is not provided).  doesn't commit automatically.
    def self.reindex_pid(pid, index_logger = nil, should_raise_errors = true)
      index_logger ||= default_index_logger
      obj = Dor.load_instance pid
      solr_doc = reindex_object obj
      index_logger.info "updated index for #{pid}"
      solr_doc
    rescue StandardError => se
      if se.is_a? ActiveFedora::ObjectNotFoundError
        index_logger.warn "failed to update index for #{pid}, object not found in Fedora"
      else
        index_logger.warn "failed to update index for #{pid}, unexpected StandardError, see main app log: #{se.backtrace}"
      end
      raise se if should_raise_errors
    rescue Exception => ex
      index_logger.error "failed to update index for #{pid}, unexpected Exception, see main app log: #{ex.backtrace}"
      raise ex # don't swallow anything worse than StandardError
    end

    # given a list of pids, retrieve those objects from fedora, index each to solr, optionally commit
    def self.reindex_pid_list(pid_list, should_commit = false)
      pid_list.each { |pid| reindex_pid pid, nil, false } # use the default logger, don't let individual errors nuke the rest of the batch
      ActiveFedora.solr.conn.commit if should_commit
    end

    # same as reindex_pid_list, but collect stats using argo's ruby-prof utility, and
    # output the results in the callgrind format.
    def self.reindex_pid_list_with_profiling(pid_list, should_commit = false)
      out_file_id = "reindex_pid_list_#{Time.now.iso8601}-#{Process.pid}"
      default_index_logger.info "#{out_file_id} traces bulk reindex for #{pid_list}"
      profiler = Argo::Profiler.new
      profiler.prof { Argo::Indexer.reindex_pid_list pid_list, should_commit }
      profiler.print_results_call_tree(out_file_id)
    end
  end
end

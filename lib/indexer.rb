module Argo
  class SimpleLogJob
    def initialize(log_val)
      @log_val = log_val
    end

    def perform
      sleep(rand 10)

      log_filename = 'tmp/simple_job.log'
      File.open(log_filename, 'a') do |log|
        log.puts "#{@log_val}"
      end
    end
  end

  # TODO: DRY up the repetition btwn here and dor_controller
  class Indexer
    @@index_logger = nil
    def self.index_logger
      return @@index_logger if @@index_logger

      @@index_logger ||= Logger.new("#{Rails.root}/log/indexer.log", 10, 3240000)
      @@index_logger.formatter = proc do |severity, datetime, progname, msg|
        date_format_str = Argo::Config.date_format_str
        "[---] [#{datetime.utc.strftime(date_format_str)}] #{msg}\n"
      end
      @@index_logger
    end

    def self.reindex_object(obj)
      solr_doc = obj.to_solr
      Dor::SearchService.solr.add(solr_doc)
    end

    def self.reindex_pid(pid)
      obj = Dor.load_instance pid
      reindex_object obj
      index_logger.info "updated index for #{pid}"
      # index_logger.debug 'Status:ok<br> Solr Document: ' + solr_doc.inspect
    rescue ActiveFedora::ObjectNotFoundError # => e
      index_logger.info "failed to update index for #{pid}, object not found in Fedora"
    rescue StandardError => se
      index_logger.error "failed to update index for #{pid}, unexpected error: #{se}"
    end

    def self.reindex_pid_list(pid_list, should_commit=false)
      pid_list.each do |pid|
        reindex_pid pid
      end
      ActiveFedora.solr.conn.commit if should_commit
    end

    def self.reindex_pid_list_with_profiling(pid_list, should_commit=false)
      out_file_id = "reindex_pid_list_#{Time.now.iso8601}-#{Process.pid}"
      index_logger.info "#{out_file_id} traces bulk reindex for #{pid_list}"
      Argo::Profiler.prof(out_file_id) { Argo::Indexer.reindex_pid_list pid_list, should_commit }
    end
  end
end

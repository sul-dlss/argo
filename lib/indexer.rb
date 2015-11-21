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

    def self.get_all_pids
      dor_pids = []
      Dor::SearchService.iterate_over_pids(:in_groups_of => 1000, :mode => :group) do |chunk|
        dor_pids += chunk
      end
      dor_pids
    end

    def self.get_pid_lists_for_full_reindex
      # TODO: get the sub-lists:
      #  uber APO 'druid:hv992ry2431'
      #  workflows  '<info:fedora/afmodel:Dor_WorkflowObject>'
      #  agreements  '<info:fedora/afmodel:agreement>'
      #  Hydrus Uber APO  'druid:zw306xn5593'
      #  All APOs (hydrus and non-hydrus)  '<info:fedora/afmodel:Dor_AdminPolicyObject>' '<info:fedora/afmodel:Hydrus_AdminPolicyObject>'
      #  collections/sets (most sets are collections as well)  '<info:fedora/afmodel:Dor_Collection>' '<info:fedora/afmodel:Hydrus_Collection>' '<info:fedora/afmodel:Dor_Set>'
      #  all the rest (items etc)   get_all_pids - all the pids we've already encountered

      uber_apo_pids = ['druid:hv992ry2431']
      workflow_pids = Argo::Indexer.get_pids_for_model_type '<info:fedora/afmodel:Dor_WorkflowObject>'
      agreement_pids = Argo::Indexer.get_pids_for_model_type '<info:fedora/afmodel:agreement>'
      hydrus_uber_apo_pids = ['druid:zw306xn5593']
      apo_pids = Argo::Indexer.get_pids_for_model_type '<info:fedora/afmodel:Dor_AdminPolicyObject>'
      hydrus_apo_pids = Argo::Indexer.get_pids_for_model_type '<info:fedora/afmodel:Hydrus_AdminPolicyObject>'
      collection_pids = Argo::Indexer.get_pids_for_model_type '<info:fedora/afmodel:Dor_Collection>'
      hydrus_collection_pids = Argo::Indexer.get_pids_for_model_type '<info:fedora/afmodel:Hydrus_Collection>'
      set_pids = Argo::Indexer.get_pids_for_model_type '<info:fedora/afmodel:Dor_Set>'

      all_pids = Argo::Indexer.get_all_pids
      remaining_pids = all_pids - (uber_apo_pids+workflow_pids+agreement_pids+hydrus_uber_apo_pids+apo_pids+hydrus_apo_pids+collection_pids+hydrus_collection_pids+set_pids)

      [uber_apo_pids, workflow_pids, agreement_pids, hydrus_uber_apo_pids, apo_pids, hydrus_apo_pids, collection_pids, hydrus_collection_pids, set_pids, remaining_pids]
    end

    def self.get_pids_for_model_type(model_type)
      Dor::SearchService.risearch "select $object from <#ri> where $object <fedora-model:hasModel> #{model_type}"
    end


    def self.reindex_all_legacy(args)
      warn '[DEPRECATION] `reindex_all` is deprecated.  Please use the bulk reindexing system instead.'
      index_log = Logger.new(File.join(Rails.root, 'log', 'reindex.log'))
      index_log.formatter = Logger::Formatter.new
      index_log.level = ENV['LOG_LEVEL'] ? Logger::SEV_LABEL.index(ENV['LOG_LEVEL']) : Logger::INFO
      $stdout.sync = true
      start_time = Time.now


      # TODO: break out pid list creation
      $stdout.puts 'Discovering PIDs...'
      index_log.info 'Discovering PIDs...'
      dor_pids = []
      solr_pids = []
      if args[:query] != ':ALL:'
        q = (args[:query].nil? || args[:query] == ':MISSING:') ? '*:*' : args[:query]
        puts q
        start = 0
        resp = Dor::SearchService.query(q, :sort => 'id asc', :rows => 1000, :start => start, :fl => ['id'])
        while resp.docs.length > 0
          solr_pids += resp.docs.collect { |doc| doc['id'] }
          start += 1000
          $stdout.print '.'
          resp = Dor::SearchService.query(q, :sort => 'id asc', :rows => 1000, :start => start, :fl => ['id'])
        end
        $stdout.puts
        msg = "Found #{solr_pids.length} PIDs in solr."
        $stdout.puts msg
        index_log.info msg
      end
      if args[:query] =~ /:(ALL|MISSING):/
        dor_pids = []
        Dor::SearchService.iterate_over_pids(:in_groups_of => 1000, :mode => :group) do |chunk|
          dor_pids += chunk
          $stderr.print '.'
        end
        $stdout.puts
        msg = "Found #{dor_pids.length} PIDs in DOR."
        $stdout.puts msg
        index_log.info msg
      end
      if dor_pids.present?
        pids = dor_pids - solr_pids
      else
        pids = solr_pids
      end
      pids.delete_if { |pid| pid !~ /druid:/ }
      time = Time.now - start_time
      msg = "#{pids.length} PIDs discovered in #{[(time / 3600).floor, (time / 60 % 60).floor, (time % 60).floor].map{|tt| tt.to_s.rjust(2, '0')}.join(':')}"
      $stdout.puts msg
      index_log.info msg


      # TODO: break out solrization of pid list
      solr = ActiveFedora.solr.conn
      pbar = ProgressBar.new('Reindexing...', pids.length)
      errors = 0
      pids.each do |pid|
        begin
          index_log.debug "Indexing #{pid}"
          obj = Dor.load_instance pid
          obj = obj.adapt_to(Dor::Item) if obj.class == ActiveFedora::Base
          if obj.is_a?(Dor::Processable) && obj.workflows.new?
            c = obj.class
            obj.workflows.save
            obj = Dor.load_instance(pid).adapt_to c
          end
          solr_doc = obj.to_solr
          solr.add solr_doc, :add_attributes => {:commitWithin => 10}
          errors = 0
        rescue Interrupt
          raise
        rescue StandardError => e
          errors += 1
          index_log.warn("Error (#{errors}) indexing #{pid}")
          index_log.error("#{e.class}: #{e.message}")
          #  if errors == 3
          #    index_log.fatal("Too many errors. Exiting.")
          #    raise e
          #  end
        end
        pbar.inc(1)
      end # pids.each
      solr.commit
      puts 'Reindexing complete'
    end
  end
end

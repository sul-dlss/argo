# frozen_string_literal: true

module Argo
  class Profiler
    # takes a block of code, starts the profiler, runs the code, stops the profiler and returns the results of the profiling.
    # example usage:
    #  profiler = Argo::Profiler.new
    #  profiler.prof { Argo::Indexer.reindex_pid_list pid_list, should_commit }
    #  profiler.print_results_call_tree(out_file_id)
    def prof
      RubyProf.start
      yield
      @results = RubyProf.stop
    end

    def print_results_call_tree(out_file_id)
      min_percent = Settings.PROFILER.CALLTREE_PRINTER_MIN_PERCENT
      pct_str_for_fname = min_percent.to_s.rjust(2, '0')
      File.open "#{Settings.PROFILER.OUTPUT_DIR}/callgrind.#{Settings.PROFILER.MEASURE_MODE}.p#{pct_str_for_fname}.#{out_file_id}", 'w' do |file|
        RubyProf::CallTreePrinter.new(@results).print(file, min_percent: min_percent)
      end
    end

    def print_results_call_stack(out_file_id)
      File.open "#{Settings.PROFILER.OUTPUT_DIR}/#{out_file_id}-stack.html", 'w' do |file|
        RubyProf::CallStackPrinter.new(@results).print(file)
      end
    end

    def print_results_flat(out_file_id)
      File.open "#{Settings.PROFILER.OUTPUT_DIR}/#{out_file_id}-flat.txt", 'w' do |file|
        RubyProf::FlatPrinterWithLineNumbers.new(@results).print(file)
      end
    end

    def print_results_graph_html(out_file_id)
      File.open "#{Settings.PROFILER.OUTPUT_DIR}/#{out_file_id}-graph.html", 'w' do |file|
        RubyProf::GraphHtmlPrinter.new(@results).print(file)
      end
    end
  end
end

module Argo
  class Profiler
    def prof
      RubyProf.start
      yield
      @results = RubyProf.stop
    end

    def print_results_call_tree(out_file_id, min_percent = 1)
      pct_str_for_fname = min_percent.to_s.rjust(2, '0')
      File.open "#{Rails.root}/log/profiler/callgrind.p#{pct_str_for_fname}.#{out_file_id}", 'w' do |file|
        RubyProf::CallTreePrinter.new(@results).print(file, :min_percent => min_percent)
      end
    end

    def print_results_call_stack(out_file_id)
      File.open "#{Rails.root}/log/profiler/#{out_file_id}-stack.html", 'w' do |file|
        RubyProf::CallStackPrinter.new(@results).print(file)
      end
    end

    def print_results_flat(out_file_id)
      File.open "#{Rails.root}/log/profiler/#{out_file_id}-flat.txt", 'w' do |file|
        RubyProf::FlatPrinterWithLineNumbers.new(@results).print(file)
      end
    end

    def print_results_graph_html(out_file_id)
      File.open "#{Rails.root}/log/profiler/#{out_file_id}-graph.html", 'w' do |file|
        RubyProf::GraphHtmlPrinter.new(@results).print(file)
      end
    end
  end
end

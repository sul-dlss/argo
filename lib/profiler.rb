module Argo
  class Profiler
    def self.prof(out_file_id)
      RubyProf.start
      yield
      results = RubyProf.stop

      File.open "#{Rails.root}/log/profiler/#{out_file_id}-graph.html", 'w' do |file|
        RubyProf::GraphHtmlPrinter.new(results).print(file)
      end

      File.open "#{Rails.root}/log/profiler/#{out_file_id}-flat.txt", 'w' do |file|
        RubyProf::FlatPrinterWithLineNumbers.new(results).print(file)
      end

      File.open "#{Rails.root}/log/profiler/#{out_file_id}-stack.html", 'w' do |file|
        RubyProf::CallStackPrinter.new(results).print(file)
      end

      File.open "#{Rails.root}/log/profiler/callgrind.#{out_file_id}", 'w' do |file|
        RubyProf::CallTreePrinter.new(results).print(file, :min_percent => 1)
      end
    end
  end
end

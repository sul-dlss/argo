# This assumes dor-services is installed and accessible. It is not a dependency of sw-oai-provider
require 'rubygems'
require File.expand_path("../../config/environment", __FILE__)
require 'dor-services'

puts '<?xml version="1.0" encoding="UTF-8"?><add>'

ARGF.each_line do |druid|
  begin
    #break unless `grep #{druid.strip} docs.xml`.empty?
    dor_item = Dor::Item.find(druid.strip)
    add_xml = Nokogiri::XML Dor::SearchService.solr.xml.add dor_item.to_solr
    puts add_xml.xpath('//doc').to_s
  rescue ActiveFedora::ObjectNotFoundError
    STDERR.puts "#{druid} not found"
    puts "<!-- #{druid} not found -->"
  end
end

puts "</add>"

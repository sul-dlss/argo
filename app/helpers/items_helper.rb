# frozen_string_literal: true

module ItemsHelper
  def stacks_url_full_size(druid, file_name)
    "#{Settings.stacks_file_url}/#{druid}/#{ERB::Util.url_encode(file_name)}"
  end

  def schema_validate(xml)
    @xsd ||= Nokogiri::XML::Schema(File.read(File.expand_path(File.dirname(__FILE__) + '/xml/mods-3-6.xsd')))
    errors = []
    unless @xsd.valid?(xml)
      @xsd.validate(xml).each do |er|
        errors << er.message
      end
    end
    errors
  end
end

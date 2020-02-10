# frozen_string_literal: true

class ModsValidator
  SCHEMA = 'app/helpers/xml/mods-3-6.xsd'
  def self.validate(doc)
    xsd = Nokogiri::XML::Schema(File.read(SCHEMA))
    errors = []
    xsd.validate(doc).each do |error|
      errors << error.message
    end
    errors
  end
end

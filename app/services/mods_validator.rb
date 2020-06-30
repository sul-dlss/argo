# frozen_string_literal: true

class ModsValidator
  SCHEMA = 'app/helpers/xml/mods-3-6.xsd'
  def self.validate(doc)
    xsd = Nokogiri::XML::Schema(File.read(SCHEMA))
    xsd.validate(doc).map(&:message)
  end
end

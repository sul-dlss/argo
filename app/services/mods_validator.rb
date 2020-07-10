# frozen_string_literal: true

class ModsValidator
  SCHEMA = 'mods-3-6.xsd'
  def self.validate(doc)
    Dir.chdir('app/helpers/xml') do
      xsd = Nokogiri::XML::Schema(File.open(SCHEMA))
      xsd.validate(doc).map(&:message)
    end
  end
end

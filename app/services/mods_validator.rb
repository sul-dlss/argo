# frozen_string_literal: true

class ModsValidator
  SCHEMA = 'mods-3-7.xsd'

  def self.validate(doc)
    Dir.chdir('app/helpers/xml') do
      xsd = Nokogiri::XML::Schema(File.open(SCHEMA))
      xsd.validate(doc).map(&:message)
    end
  end
end

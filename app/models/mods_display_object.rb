class ModsDisplayObject
  include ModsDisplay::ModelExtension

  attr_reader :xml

  def initialize xml
    @xml=xml
  end

  def modsxml
    @xml
  end

  mods_xml_source do |obj|
    # puts obj.xml
    obj.xml
  end
end

# frozen_string_literal: true

# Parses rights XML to produce a label
class RightsLabeler
  # @param [String] rights_xml rights metadata serialized as XML in string form
  # @return [String] a label expressing the rights of the object
  def self.label(rights_xml)
    new(rights_xml).label
  end

  # @param [String] rights_xml rights metadata serialized as XML in string form
  def initialize(rights_xml)
    @rights_xml = Nokogiri::XML(rights_xml)
  end

  # @return [String] a label expressing the rights of the object
  def label
    machine_read_access_node = rights_xml.search('//rightsMetadata/access[@type="read"]/machine').first
    machine_discover_access_node = rights_xml.search('//rightsMetadata/access[@type="discover"]/machine').first

    if machine_read_access_node && machine_read_access_node.search('./group[text()="Stanford" or text()="stanford"]').size.positive?
      if machine_read_access_node.search('./group[@rule="no-download"]').size.positive?
        'stanford-nd'
      else
        'stanford'
      end
    elsif machine_read_access_node && machine_read_access_node.search('./world').size.positive?
      if machine_read_access_node.search('./world[@rule="no-download"]').size.positive?
        'world-nd'
      else
        'world'
      end
    elsif machine_read_access_node && machine_read_access_node.search('./location[text()="spec"]').size.positive?
      'loc:spec'
    elsif machine_read_access_node && machine_read_access_node.search('./location[text()="music"]').size.positive?
      'loc:music'
    elsif machine_discover_access_node && machine_discover_access_node.search('./world').size.positive?
      # if it's not stanford restricted, world readable, or location restricted, but it is world discoverable, it's "citation only"
      'citation-only'
    elsif machine_discover_access_node && machine_discover_access_node.search('./none').size.positive?
      # if it's not even discoverable, it's "dark"
      'dark'
    end
  end

  private

  attr_reader :rights_xml
end

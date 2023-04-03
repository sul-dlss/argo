# frozen_string_literal: true

# Creates the descriptive XML that we display on purl.stanford.edu
class ModsService
  attr_reader :cocina_object

  MODS_NS = "http://www.loc.gov/mods/v3"

  def initialize(cocina_object)
    @cocina_object = cocina_object
  end

  # @return [Nokogiri::XML::Document] A copy of the descriptiveMetadata of the object, to be modified
  def doc
    @doc ||= Cocina::Models::Mapping::ToMods::Description.transform(cocina_object.description, cocina_object.externalIdentifier)
  end

  # @return [String] Public descriptive medatada XML
  def to_xml
    ng_xml(include_access_conditions: true).to_xml
  end

  # @return [Nokogiri::XML::Document]
  def ng_xml(include_access_conditions: true)
    @ng_xml ||= begin
      add_collection_reference!
      Mods::AccessConditions.add(public_mods: doc, access: cocina_object.access) if include_access_conditions
      add_constituent_relations!
      add_doi
      strip_comments!

      new_doc = Nokogiri::XML(doc.to_xml, &:noblanks)
      new_doc.encoding = "UTF-8"
      new_doc
    end
  end

  private

  def strip_comments!
    doc.xpath("//comment()").remove
  end

  # Export DOI into the public descMetadata to allow PURL to display it
  def add_doi
    return unless cocina_object.dro? && cocina_object.identification.doi

    identifier = doc.create_element("identifier", xmlns: MODS_NS)
    identifier.content = "https://doi.org/#{cocina_object.identification.doi}"
    identifier["type"] = "doi"
    identifier["displayLabel"] = "DOI"
    doc.root << identifier
  end

  # expand constituent relations into relatedItem references -- see JUMBO-18
  # @return [Void]
  def add_constituent_relations!
    Mods::VirtualObject.for(druid: cocina_object.externalIdentifier).each do |solr_doc|
      # create the MODS relation
      related_item = doc.create_element("relatedItem", xmlns: MODS_NS)
      related_item["type"] = "host"
      related_item["displayLabel"] = "Appears in"

      # load the title from the virtual object's DC.title
      title_info = doc.create_element("titleInfo", xmlns: MODS_NS)
      title = doc.create_element("title", xmlns: MODS_NS)
      title.content = solr_doc.fetch(:title)
      title_info << title
      related_item << title_info

      # point to the PURL for the virtual object
      location = doc.create_element("location", xmlns: MODS_NS)
      url = doc.create_element("url", xmlns: MODS_NS)
      url.content = purl_url(solr_doc.fetch(:id))
      location << url
      related_item << location

      # finish up by adding relation to public MODS
      doc.root << related_item
    end
  end

  def purl_url(druid)
    "#{Settings.purl_url}/#{druid.delete_prefix("druid:")}"
  end

  # Adds to desc metadata a relatedItem with information about the collection this object belongs to.
  # For use in published mods and mods-to-DC conversion.
  # @return [Void]
  def add_collection_reference!
    return if cocina_object.collection? || cocina_object.structural&.isMemberOf.blank?

    collections = Dor::Services::Client.object(cocina_object.externalIdentifier).collections

    remove_related_item_nodes_for_collections!

    collections.each do |cocina_collection|
      add_related_item_node_for_collection! cocina_collection
    end
  end

  # Remove existing relatedItem entries for collections from descMetadata
  def remove_related_item_nodes_for_collections!
    doc.search('/mods:mods/mods:relatedItem[@type="host"]/mods:typeOfResource[@collection=\'yes\']', "mods" => "http://www.loc.gov/mods/v3").each do |node|
      node.parent.remove
    end
  end

  def add_related_item_node_for_collection!(cocina_collection)
    title_node = Nokogiri::XML::Node.new("title", doc)
    title_node.content = Cocina::Models::Builders::TitleBuilder.build(cocina_collection.description.title)

    title_info_node = Nokogiri::XML::Node.new("titleInfo", doc)
    title_info_node.add_child(title_node)

    # e.g.:
    #   <location>
    #     <url>http://purl.stanford.edu/rh056sr3313</url>
    #   </location>
    loc_node = doc.create_element("location", xmlns: MODS_NS)
    url_node = doc.create_element("url", xmlns: MODS_NS)
    url_node.content = purl_url(cocina_collection.externalIdentifier)
    loc_node << url_node

    type_node = doc.create_element("typeOfResource", xmlns: MODS_NS)
    type_node["collection"] = "yes"

    related_item_node = doc.create_element("relatedItem", xmlns: MODS_NS)
    related_item_node["type"] = "host"

    related_item_node.add_child(title_info_node)
    related_item_node.add_child(loc_node)
    related_item_node.add_child(type_node)

    doc.root.add_child(related_item_node)
  end
end

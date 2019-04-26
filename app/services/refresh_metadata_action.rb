# frozen_string_literal: true

# TODO: move this and common-accessioning's DescMetadataService to dor-services-app
class RefreshMetadataAction
  def self.run(object)
    new(object).run(object.descMetadata)
  end

  def initialize(object)
    @object = object
  end

  def run(datastream)
    content = fetch_datastream
    return nil if content.nil?

    datastream.dsLabel = 'Descriptive Metadata'
    datastream.ng_xml = Nokogiri::XML(content)
    datastream.ng_xml.normalize_text!
    datastream.content = datastream.ng_xml.to_xml
  end

  private

  def fetch_datastream
    candidates = @object.identityMetadata.otherId.collect(&:to_s)
    metadata_id = Dor::MetadataService.resolvable(candidates).first
    metadata_id.nil? ? nil : Dor::MetadataService.fetch(metadata_id.to_s)
  end
end

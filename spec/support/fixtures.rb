# frozen_string_literal: true

module FixtureHelpers
  def druid_to_path(druid, flavor = 'xml')
    fixture_mask = File.join(File.dirname(__FILE__), '..', 'fixtures', "*_#{druid.sub(/:/, '_')}.#{flavor}")
    other_mask   = Rails.root.join('fedora_conf', 'data', "#{druid.sub(/druid:/, '')}.#{flavor}")
    Dir[fixture_mask].first || Dir[other_mask].first
  end

  def instantiate_fixture(druid, klass = ActiveFedora::Base)
    fname = druid_to_path(druid)
    Rails.logger.debug "instantiate_fixture(#{druid}) ==> #{fname}"
    return nil if fname.nil?

    item = item_from_foxml(File.read(fname), klass)

    if klass == ActiveFedora::Base
      item.adapt_to_cmodel
    else
      item
    end
  end

  # Highly similar to https://github.com/sul-dlss/dor-services/blob/master/spec/foxml_helper.rb
  def item_from_foxml(foxml, item_class = Dor::Base, other_class = ActiveFedora::OmDatastream)
    foxml = Nokogiri::XML(foxml) unless foxml.is_a?(Nokogiri::XML::Node)
    xml_streams = foxml.xpath('//foxml:datastream')
    properties = Hash[foxml.xpath('//foxml:objectProperties/foxml:property').collect do |node|
      [node['NAME'].split(/#/).last, node['VALUE']]
    end]
    result = item_class.new(pid: foxml.root['PID'])
    result.label    = properties['label']
    result.owner_id = properties['ownerId']
    xml_streams.each do |stream|
      content = stream.xpath('.//foxml:xmlContent/*').first.to_xml
      dsid = stream['ID']
      ds = result.datastreams[dsid]
      if ds.nil?
        ds = other_class.new(result, dsid)
        result.add_datastream(ds)
      end

      result.datastreams[dsid] = if ds.is_a?(other_class)
                                   ds.class.from_xml(Nokogiri::XML(content), ds)
                                 elsif ds.is_a?(ActiveFedora::RelsExtDatastream)
                                   ds.class.from_xml(content, ds)
                                 else
                                   ds.class.from_xml(ds, stream)
                                 end
    rescue StandardError
      # TODO: (?) rescue if 1 datastream failed
    end

    # stub item and datastream repo access methods
    result.datastreams.each_pair do |_dsid, ds|
      # if ds.is_a?(ActiveFedora::OmDatastream) && !ds.is_a?(Dor::WorkflowDs)
      #   ds.instance_eval do
      #     def content       ; self.ng_xml.to_s                 ; end
      #     def content=(val) ; self.ng_xml = Nokogiri::XML(val) ; end
      #   end
      # end
      ds.instance_eval do
        def save
          true
        end
      end
    end
    result.instance_eval do
      def save
        true
      end
    end
    result
  end
end

RSpec.configure do |config|
  config.include FixtureHelpers
end

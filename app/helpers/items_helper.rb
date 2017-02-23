require 'stanford-mods'
module ItemsHelper
  def stacks_url_full_size(obj, file_name)
    druid = obj.pid
    "#{Settings.STACKS_FILE_URL}/#{druid}/#{URI.encode(file_name)}"
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

  def mods_discoverable(xml)
    messages = []
    mods_rec = Stanford::Mods::Record.new
    mods_rec.from_nk_node(xml)
    # should have a title
    title = mods_rec.sw_full_title
    messages << 'Missing title.' unless title && title.length > 0
    # should have a dateIssued
    vals = mods_rec.term_values([:origin_info, :dateIssued])
    if vals
      vals = vals.concat mods_rec.term_values([:origin_info, :dateCreated]) if mods_rec.term_values([:origin_info, :dateCreated])
    else
      vals = mods_rec.term_values([:origin_info, :dateCreated])
    end
    messages << 'Missing dateIssued or dateCreated.' unless vals && vals.length > 0
    # should have a typeOfResource
    good_formats = ['still image', 'mixed material', 'moving image', 'three dimensional object', 'cartographic', 'sound recording-musical', 'sound recording-nonmusical', 'software, multimedia']
    format = mods_rec.term_values(:typeOfResource)
    messages << 'Missing or invalid typeOfResource' unless format && format.length > 0 && good_formats.include?(format.first)
    messages
  end
end

# encoding: utf-8
module ApoHelper
  def utf_val
    "hello world ©"
  end

  def options_for_use_license_type use_license_map, cur_use_license
    use_license_map.map do |key, val|
      if val[:deprecation_warning] != nil && key == cur_use_license
        ["#{val[:human_readable]} (#{val[:deprecation_warning]})", key]
      elsif val[:deprecation_warning] == nil
        [val[:human_readable], key]
      end
    end.compact
  end

  def license_options apo_obj
    cur_use_license = apo_obj ? apo_obj.use_license : nil
    [['Citation Only','']] + 
    options_for_use_license_type(Dor::Editable::CREATIVE_COMMONS_USE_LICENSES, cur_use_license) + 
    options_for_use_license_type(Dor::Editable::OPEN_DATA_COMMONS_USE_LICENSES, cur_use_license)
  end

  def default_rights_options
    [
      %w(World world),
      %w(Stanford stanford),
      ['Dark (Preserve Only)', 'dark'],
      ['Citation Only', 'none']
    ]
  end

  def options_for_desc_md
    [
      ['MODS'],['TEI']
    ]
  end

  def apo_metadata_sources
    [['Symphony'],['DOR'],['MDToolkit']]
  end

  def workflow_options
    q = 'objectType_ssim:workflow '
    result = Dor::SearchService.query(q, :rows => 99999, :fl => 'id,tag_ssim,dc_title_tesim').docs
    result.sort! do |a,b|
      a['dc_title_tesim'].to_s <=> b['dc_title_tesim'].to_s
    end
    result.collect do |doc|
      [Array(doc['dc_title_tesim']).first,doc['dc_title_tesim'].first.to_s]
    end
  end

  def default_workflow_option
    return 'registrationWF'
  end

  def agreement_options
    q = 'objectType_ssim:agreement '
    result = Dor::SearchService.query(q, :rows => 99999, :fl => 'id,tag_ssim,dc_title_tesim').docs
    result.sort! do |a,b|
      a['dc_title_tesim'].to_s <=> b['dc_title_tesim'].to_s
    end
    result.collect do |doc|
      [Array(doc['dc_title_tesim']).first, doc['id'].to_s]
    end
  end
end

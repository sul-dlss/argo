module ApoHelper
  # return a list of lists, where the sublists are pairs, with the first element being the text to display
  # in the selectbox, and the second being the value to submit for the entry.  include only non-deprecated
  # entries, unless the current value is a deprecated entry, in which case, include that entry with the
  # deprecation warning in a parenthetical.
  def options_for_use_license_type(use_license_map, cur_use_license)
    use_license_map.map do |key, val|
      if val[:deprecation_warning].nil?
        [val[:human_readable], key]
      elsif key == cur_use_license
        ["#{val[:human_readable]} (#{val[:deprecation_warning]})", key]
      end
    end.compact # the map block will produce nils for unused deprecated entries, compact will get rid of them
  end

  def license_options(apo_obj)
    cur_use_license = apo_obj ? apo_obj.use_license : nil
    [['-- none --', '']] +
    options_for_use_license_type(Dor::Editable::CREATIVE_COMMONS_USE_LICENSES, cur_use_license) +
    options_for_use_license_type(Dor::Editable::OPEN_DATA_COMMONS_USE_LICENSES, cur_use_license)
  end

  def options_for_desc_md
    [
      ['MODS'], ['TEI']
    ]
  end

  def apo_metadata_sources
    [['Symphony'], ['DOR'], ['MDToolkit']]
  end

  def workflow_options
    q = 'objectType_ssim:workflow '
    result = Dor::SearchService.query(q, :rows => 99999, :fl => 'id,tag_ssim,dc_title_tesim')['response']['docs']
    result.sort! do |a, b|
      a['dc_title_tesim'].to_s <=> b['dc_title_tesim'].to_s
    end
    result.collect do |doc|
      [Array(doc['dc_title_tesim']).first, doc['dc_title_tesim'].first.to_s]
    end
  end

  def default_workflow_option
    'registrationWF'
  end

  def agreement_options
    q = 'objectType_ssim:agreement '
    result = Dor::SearchService.query(q, :rows => 99999, :fl => 'id,tag_ssim,dc_title_tesim')['response']['docs']
    result.sort! do |a, b|
      a['dc_title_tesim'].to_s <=> b['dc_title_tesim'].to_s
    end
    result.collect do |doc|
      [Array(doc['dc_title_tesim']).first, doc['id'].to_s]
    end
  end
end

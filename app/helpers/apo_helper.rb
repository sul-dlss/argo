# encoding: utf-8
module ApoHelper
  def utf_val
    "hello world ©"
  end

  def creative_commons_options
    [
      ['Citation Only',''],
      ['Attribution 3.0 Unported', 'by'],
      ['Attribution Share Alike 3.0 Unported','by_sa'],
      ['Attribution No Derivatives 3.0 Unported', 'by-nd'],
      ['Attribution Non-Commercial 3.0 Unported', 'by-nc'],
      ['Attribution Non-Commercial Share Alike 3.0 Unported', 'by-nc-sa'],
      ['Attribution Non-commercial, No Derivatives 3.0 Unported', 'by-nc-nd']
    ]
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

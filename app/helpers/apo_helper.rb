# frozen_string_literal: true

module ApoHelper
  def options_for_desc_md
    [
      ['MODS']
    ]
  end

  def apo_metadata_sources
    [['Symphony'], ['DOR']]
  end

  def workflow_options
    q = 'objectType_ssim:workflow '
    result = Dor::SearchService.query(q, rows: 99999, fl: 'id,tag_ssim,sw_display_title_tesim')['response']['docs']
    result.sort! do |a, b|
      a['sw_display_title_tesim'].to_s <=> b['sw_display_title_tesim'].to_s
    end
    result.collect do |doc|
      [Array(doc['sw_display_title_tesim']).first.to_s, Array(doc['sw_display_title_tesim']).first.to_s]
    end
  end

  def agreement_options
    q = 'objectType_ssim:agreement '
    result = Dor::SearchService.query(q, rows: 99999, fl: 'id,tag_ssim,sw_display_title_tesim')['response']['docs']
    result.sort! do |a, b|
      a['sw_display_title_tesim'].to_s <=> b['sw_display_title_tesim'].to_s
    end
    result.collect do |doc|
      [Array(doc['sw_display_title_tesim']).first.to_s, doc['id'].to_s]
    end
  end
end

# frozen_string_literal: true

module ApoHelper
  # @return [Array<Array<String, String>] array suitable for select_tag options
  def workflow_options
    # per https://github.com/sul-dlss/argo/issues/3741, this should be hardcoded
    %w[
      accessionWF
      gisAssemblyWF
      gisDeliveryWF
      gisDiscoveryWF
      goobiWF
      registrationWF
      wasCrawlDisseminationWF
      wasCrawlPreassemblyWF
      wasSeedPreassemblyWF
    ].map do |workflow|
      [workflow, workflow]
    end
  end

  def agreement_options
    q = 'objectType_ssim:agreement'
    result = SearchService.query(q, rows: 99_999, fl: 'id,tag_ssim,sw_display_title_tesim')['response']['docs']
    result.sort! do |a, b|
      a['sw_display_title_tesim'].to_s <=> b['sw_display_title_tesim'].to_s
    end
    result.collect do |doc|
      [Array(doc['sw_display_title_tesim']).first.to_s, doc['id'].to_s]
    end
  end
end

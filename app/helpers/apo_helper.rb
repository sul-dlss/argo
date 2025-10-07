# frozen_string_literal: true

module ApoHelper
  def agreement_options
    q = "#{SolrDocument::FIELD_OBJECT_TYPE}:agreement"
    result = SearchService.query(q, rows: 99_999, fl: 'id,tag_ssim,display_title_ss')['response']['docs']
    result.sort! do |a, b|
      a['display_title_ss'].to_s <=> b['display_title_ss'].to_s
    end
    result.collect do |doc|
      [Array(doc['display_title_ss']).first.to_s, doc['id'].to_s]
    end
  end
end

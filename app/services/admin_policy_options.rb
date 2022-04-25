# frozen_string_literal: true

# Queries the list of AdminPolicies a user may access
class AdminPolicyOptions
  def self.for(user_with_groups)
    groups = user_with_groups.groups
    return [] if groups.blank?

    q = groups.filter_map { |key| %(apo_register_permissions_ssim:"#{key}") unless key.end_with?('/administrator') }.join(' OR ')

    result = SearchService.query(
      q,
      defType: 'lucene',
      rows: 99_999,
      fl: 'id,tag_ssim,sw_display_title_tesim',
      fq: ['objectType_ssim:adminPolicy', '!tag_ssim:"Project : Hydrus"']
    )['response']['docs']

    result.sort! do |a, b|
      Array(a['tag_ssim']).include?('AdminPolicy : default') ? -1 : a['sw_display_title_tesim'].to_s <=> b['sw_display_title_tesim'].to_s
    end
    result.map do |doc|
      [Array(doc['sw_display_title_tesim']).first, doc['id'].to_s]
    end
  end
end

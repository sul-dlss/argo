# frozen_string_literal: true

# Queries the list of AdminPolicies a user may access
class AdminPolicyOptions
  def self.for(user_with_groups)
    groups = user_with_groups.groups
    return [] if groups.blank?

    q = groups.filter_map { |key| %(apo_register_permissions_ssim:"#{key}") unless key.end_with?("/administrator") }.join(" OR ")

    SearchService
      .query(
        q, defType: "lucene", rows: 99_999, fl: "id,tag_ssim,#{SolrDocument::FIELD_TITLE}",
        fq: ["objectType_ssim:adminPolicy", '!tag_ssim:"Project : Hydrus"', '!tag_ssim:"APO status : inactive"']
      )
      .dig("response", "docs")
      .sort_by { |doc| doc.fetch(SolrDocument::FIELD_TITLE).first.downcase.delete("[]") }
      .map { |doc| [Array(doc[SolrDocument::FIELD_TITLE]).first, doc["id"].to_s] }
  end
end

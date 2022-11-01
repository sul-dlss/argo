# frozen_string_literal: true

##
# Determine user authorization based on index
class PermittedQueries
  attr_reader :groups, :known_roles

  PERMITTED_COLLECTIONS_LIMIT = 5000
  INACTIVE_TAG = "collection status : inactive"

  ##
  # @params groups
  # @params [Boolean] is_admin
  # @params [Array<String>] known_roles
  def initialize(groups, known_roles, is_admin)
    @groups = groups
    @known_roles = known_roles
    @admin = is_admin
  end

  ##
  # Ported over code from `app/models/user.rb`
  # Also queries Solr based on groups
  # @return [Array[String]] list of DRUIDs from APOs that this User can view
  def permitted_apos
    query = groups.map { |g| RSolr.solr_escape(g) }.join(" OR ")

    clauses = if admin?
      ["*:*"]
    else
      known_roles.map do |role|
        "apo_role_#{role}_ssim:(#{query})"
      end
    end

    resp = repository.search(
      q: clauses.join(" OR "),
      defType: "lucene",
      rows: 1000,
      fl: "id",
      fq: ["objectType_ssim:adminPolicy", "!project_tag_ssim:Hydrus"]
    )["response"]["docs"]
    resp.map { |doc| doc["id"] }
  end

  ##
  # Returns a list of collections that the user has access to. Excludes those with the tag: "collection status : inactive"
  # @return [Array<Array<String>>] Sorted array of pairs of strings, each pair like: ["Title (DRUID)", "DRUID"]
  def permitted_collections
    q = if admin?
      "*:*"
    elsif permitted_apos.empty?
      "-id:*"
    else
      permitted_apos.map { |druid| "#{SolrDocument::FIELD_APO_ID}:\"info:fedora/#{druid}\"" }.join(" OR ")
    end

    # Note that if there are more than PERMITTED_COLLECTIONS_LIMIT collections, not all collections may be returned,
    # especially for admins.
    result = repository.search(
      q:,
      defType: "lucene",
      rows: PERMITTED_COLLECTIONS_LIMIT,
      fl: "id,sw_display_title_tesim",
      fq: ["objectType_ssim:collection", "!tag_ssim:\"#{INACTIVE_TAG}\""]
    )["response"]["docs"]
    result.sort! do |a, b|
      a["sw_display_title_tesim"].to_s <=> b["sw_display_title_tesim"].to_s
    end

    [["None", ""]] + result.map do |doc|
      ["#{Array(doc["sw_display_title_tesim"]).first} (#{doc["id"]})", doc["id"].to_s]
    end
  end

  private

  def admin?
    @admin == true
  end

  delegate :repository, to: :blacklight_config

  def blacklight_config
    @blacklight_config ||= CatalogController.blacklight_config.configure
  end
end

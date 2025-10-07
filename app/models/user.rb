# frozen_string_literal: true

class User < ApplicationRecord
  # Connects this user object to Blacklights Bookmarks and Folders.
  include Blacklight::User

  has_many :bulk_actions

  # The code base requires Arrays for these constants, for intersection ops.
  ADMIN_GROUPS = %w[workgroup:sdr:administrator-role].freeze
  MANAGER_GROUPS = %w[workgroup:sdr:manager-role].freeze
  VIEWER_GROUPS = %w[workgroup:sdr:viewer-role].freeze
  SDR_API_AUTHORIZED_GROUPS = %w[workgroup:sdr:api-authorized-users].freeze

  # @return [Array<String>] list of roles the user can adopt. These must match the roles that Ability looks for.
  # NOTE: 'sdr-administrator' and 'sdr-viewer' may be removed in the future. See https://github.com/sul-dlss/dor-services-app/issues/3856
  KNOWN_ROLES = %w[
    dor-apo-depositor
    dor-apo-manager
    dor-apo-viewer
    sdr-administrator
    sdr-viewer
  ].freeze

  devise :remote_user_authenticatable

  delegate :permitted_apos, :permitted_collections, to: :permitted_queries

  # Set by ApplicationController from the request env
  attr_accessor :display_name

  def permitted_queries
    @permitted_queries ||= PermittedQueries.new(groups, KNOWN_ROLES, admin?)
  end

  def to_s
    display_name || sunetid
  end

  # Queries Solr for a given record, returning synthesized role strings that are defined. Searches:
  # (1) for User by sunet id
  # (2) groups actually contains the sunetid, so it is just looking at different solr fields
  # NOTE: includes legacy roles that have to be translated
  # @param [String] admin_policy_id Object identifier of an Admin Policy
  # @return [Array<String>] set of roles permitted for DRUID
  def roles(admin_policy_id)
    return [] if admin_policy_id.blank?

    @role_cache ||= {}
    return @role_cache[admin_policy_id] if @role_cache[admin_policy_id]

    # Try to retrieve a Solr doc
    obj_doc = SearchService.query("id:\"#{admin_policy_id}\"")['response']['docs'].first || {}
    return [] if obj_doc.empty?

    apo_roles = Set.new
    # Check additional known roles
    KNOWN_ROLES.each do |role|
      solr_apo_roles = ["apo_role_#{role}_ssim", "apo_role_person_#{role}_ssim"]
      apo_roles << role if solr_apo_roles.any? { |r| solr_role_allowed?(obj_doc, r) }
    end
    # store and return an array of roles (Set.sort is an Array)
    @role_cache[admin_policy_id] = apo_roles.sort
  end

  # Validate a user belongs to a workgroup allowed to access a DOR object
  # @param dor_doc [Hash] A Solr document for a DOR object
  # @param role [String] Role to be validated for the DOR object
  def solr_role_allowed?(solr_doc, solr_role)
    # solr_doc[solr_role] returns an array of groups permitted to adopt the role
    (solr_doc[solr_role] & groups).present?
  end

  # Allow a repository admin to see the repository with different permissions
  # @param grps [Array<String>|String|nil] set of groups
  def set_groups_to_impersonate(grps)
    # remove any existing impersonation (see #groups below)
    @role_cache = {}
    @groups_to_impersonate = if grps.blank?
                               nil
                             else
                               # NOTE: Do not allow impersonation to grant SDR API access!
                               Array(grps) - SDR_API_AUTHORIZED_GROUPS
                             end
  end

  # @return [Array<String>] list of groups the user is a member of including those
  #   they are impersonating
  def groups
    return @groups_to_impersonate if @groups_to_impersonate.present?

    Array(webauth_groups)
  end

  # @return [Array<String>] the list of webauth groups that were set and the users sunetid
  def webauth_groups
    ["sunetid:#{login}"] + Array(@webauth_groups)
  end

  def webauth_groups=(groups)
    @webauth_groups = groups.map { |g| "workgroup:#{g}" }
  end

  # @return [Boolean] is the user a repository wide administrator
  def admin?
    !(groups & ADMIN_GROUPS).empty?
  end

  # @return [Boolean] is the user a repository wide administrator without
  #     taking into account impersonation.
  def webauth_admin?
    # we're casting to an array, because this may be called in a background job,
    # where webauth_groups has not been set.
    !(Array(webauth_groups) & ADMIN_GROUPS).empty?
  end

  # @return [Boolean] is the user a repository wide manager
  def manager?
    !(groups & MANAGER_GROUPS).empty?
  end

  # @return [Boolean] is the user a repository wide viewer
  def viewer?
    !(groups & VIEWER_GROUPS).empty?
  end

  # @return [Boolean] is the user authorized to use SDR API
  def sdr_api_authorized?
    !(groups & SDR_API_AUTHORIZED_GROUPS).empty?
  end

  def login
    sunetid
  end
end

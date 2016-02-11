class User < ActiveRecord::Base
  # Connects this user object to Blacklights Bookmarks and Folders.
  include Blacklight::User
  has_many :bulk_actions

  attr_accessor :webauth

  delegate :permitted_apos, :permitted_collections, to: :permitted_queries

  def permitted_queries
    @permitted_queries ||= PermittedQueries.new(groups, known_roles, is_admin)
  end

  def self.find_or_create_by_webauth(webauth)
    result = find_or_create_by(:sunetid => webauth.login)
    result.webauth = webauth
    result
  end

  def self.find_or_create_by_remoteuser(username)
    find_or_create_by(:sunetid => username)
  end

  def to_s
    return sunetid unless webauth
    webauth.attributes['DISPLAYNAME'] || webauth.login
  end

  @role_cache = {}

  # Queries Solr for a given record, returning synthesized role strings that are defined. Searches:
  # (1) for User by sunet id
  # (2) groups actually contains the sunetid, so it is just looking at different solr fields
  # NOTE: includes legacy roles that have to be translated
  # @param [String] DRUID, fully qualified
  # @return [Array[String]] list of roles
  def roles(pid)
    @role_cache ||= {}
    return @role_cache[pid] if @role_cache[pid]

    resp = Dor::SearchService.query('id:"' + pid + '"')['response']['docs'].first || {}
    toret = []
    my_groups = groups
    %w(apo_role_group_manager_ssim apo_role_person_manager_ssim).each do |key|
      toret << 'dor-apo-manager' if resp[key] && (resp[key] & my_groups).length > 0
    end

    known_roles.each do |role|
      ["apo_role_#{role}_ssim", "apo_role_person_#{role}_ssim"].each do |key|
        toret << role if resp[key] && (resp[key] & my_groups).length > 0
      end
    end
    @role_cache[pid] = toret # store this for now, there may be several role related calls
    toret
  end

  # @return [Array<String>] list of apos the user is allowed to view
  def known_roles
    ['dor-administrator', 'sdr-administrator', 'dor-viewer', 'sdr-viewer', 'dor-apo-creator', 'dor-apo-manager', 'dor-apo-depositor', 'dor-apo-reviewer', 'dor-apo-metadata', 'dor-apo-viewer']
  end

  @groups_to_impersonate = nil
  # Allow a repository admin to see the repository as if they had a different set of permissions
  # @param [Array<String>] set of groups
  def set_groups_to_impersonate(grps)
    @groups_to_impersonate = grps
  end

  def groups
    return @groups_to_impersonate if @groups_to_impersonate
    perm_keys = ["sunetid:#{login}"]
    return perm_keys unless webauth && webauth.privgroup.present?
    perm_keys + webauth.privgroup.split(/\|/).collect { |g| "workgroup:#{g}" }
  end

  # @return [Boolean] is the user a repository wide administrator
  def is_admin
    !(groups & ADMIN_GROUPS).empty?
  end

  # @return [Boolean] is the user a repository wide viewer
  def is_viewer
    !(groups & VIEWER_GROUPS).empty?
  end

  # @return [Boolean] is the user a repo wide manager
  def is_manager
    !(groups & MANAGER_GROUPS).empty?
  end

  # The convention is for boolean is_XYZ methods to be interrogative (end in "?")
  alias_method :is_admin?,   :is_admin
  alias_method :is_viewer?,  :is_viewer
  alias_method :is_manager?, :is_manager

  def login
    webauth ? webauth.login : sunetid
  end

  ##
  # @return [Boolean]
  def can_view_something?
    is_admin || is_manager || is_viewer || permitted_apos.length > 0
  end
end

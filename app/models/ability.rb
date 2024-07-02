# frozen_string_literal: true

# notes for those who are new to CanCan:
#  * basic intro to permission checking w/ CanCan:  https://github.com/CanCanCommunity/cancancan/wiki/Checking-Abilities
#  * rules which are defined later have higher precedence, i.e. the last rule defined is the first rule applied.
#    * more info at https://github.com/CanCanCommunity/cancancan/wiki/Ability-Precedence
#  * Argo uses this pattern for checking permissions via CanCan:  https://github.com/CanCanCommunity/cancancan/wiki/Non-RESTful-Controllers
#
# Argo specific notes:
#   * permissions granted by an APO apply to objects governed by the APO, as well as to the APO itself
class Ability
  include CanCan::Ability

  DRO_MODELS = [Cocina::Models::DRO, Cocina::Models::DROWithMetadata, Cocina::Models::DROLite].freeze
  COLLECTION_MODELS = [Cocina::Models::Collection, Cocina::Models::CollectionWithMetadata,
                       Cocina::Models::CollectionLite].freeze
  ADMIN_POLICY_MODELS = [Cocina::Models::AdminPolicy, Cocina::Models::AdminPolicyWithMetadata,
                         Cocina::Models::AdminPolicyLite].freeze

  def initialize(current_user)
    @current_user = current_user || guest_user
    grant_permissions
  end

  attr_reader :current_user

  def grant_permissions
    can :manage, :all if current_user.admin?
    cannot :impersonate, User unless current_user.webauth_admin?

    # NOTE: Lock down SDR token creation to *explicitly* authorized users
    cannot :create, :token
    can :create, :token if current_user.sdr_api_authorized?

    if current_user.manager?
      can %i[update manage_governing_apo view_content read],
          DRO_MODELS + COLLECTION_MODELS
      can :create, ADMIN_POLICY_MODELS
    end

    can %i[read view_content], DRO_MODELS + COLLECTION_MODELS + ADMIN_POLICY_MODELS if current_user.viewer?

    can :update, ADMIN_POLICY_MODELS do |cocina_object|
      can_manage_items? current_user.roles(cocina_object.externalIdentifier)
    end

    can :update, COLLECTION_MODELS + DRO_MODELS do |cocina_object|
      can_manage_items? current_user.roles(cocina_object.administrative.hasAdminPolicy)
    end

    can :manage_governing_apo, COLLECTION_MODELS + DRO_MODELS do |cocina_object, new_apo_id|
      # user must have management privileges on both the target APO and the APO currently governing the item
      can_manage_items?(current_user.roles(new_apo_id)) && can?(:update, cocina_object)
    end

    can :view_content, DRO_MODELS do |cocina_item|
      can_view? current_user.roles(cocina_item.administrative.hasAdminPolicy)
    end

    can :read, COLLECTION_MODELS + DRO_MODELS do |cocina_object|
      can_view? current_user.roles(cocina_object.administrative.hasAdminPolicy)
    end

    can :read, ADMIN_POLICY_MODELS do |cocina_admin_policy|
      can_view?(current_user.roles(cocina_admin_policy.externalIdentifier)) ||
        can_view?(current_user.roles(cocina_admin_policy.administrative.hasAdminPolicy))
    end
  end

  # Returns true if they have been granted permission to update all workflows or
  # The status is currently "waiting" and they can manage that item
  def can_update_workflow?(status, cocina_object)
    can?(:update, :workflow) ||
      (status == 'waiting' && can?(:update, cocina_object))
  end

  private

  # We compare the roles a user has on a AdminPolicy, with these roles to determine
  # what sort of access to grant the user:
  MANAGE_ITEM_ROLES = %w[dor-administrator sdr-administrator dor-apo-manager dor-apo-depositor].freeze
  VIEW_ROLES = (MANAGE_ITEM_ROLES + %w[dor-viewer sdr-viewer]).freeze

  def can_manage_items?(user_roles)
    intersect user_roles, MANAGE_ITEM_ROLES
  end

  def can_view?(user_roles)
    intersect user_roles, VIEW_ROLES
  end

  def intersect(arr1, arr2)
    !(arr1 & arr2).empty?
  end

  # A current_user who isn't logged in
  def guest_user
    User.new
  end
end

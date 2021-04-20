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

  def initialize(current_user)
    @current_user = current_user || guest_user
    grant_permissions
  end

  attr_reader :current_user

  def grant_permissions
    can :manage, :all if current_user.admin?
    cannot :impersonate, User unless current_user.webauth_admin?

    if current_user.manager?
      can %i[manage_item manage_desc_metadata manage_governing_apo view_content view_metadata],
          [NilModel, Cocina::Models::DRO, Cocina::Models::Collection]
      can :create, Cocina::Models::AdminPolicy
    end

    can %i[view_metadata view_content], [Cocina::Models::DRO, Cocina::Models::Collection, Cocina::Models::AdminPolicy] if current_user.viewer?

    can :manage_item, Cocina::Models::AdminPolicy do |cocina_object|
      can_manage_items? current_user.roles(cocina_object.externalIdentifier)
    end

    can :manage_item, [Cocina::Models::Collection, Cocina::Models::DRO] do |cocina_object|
      can_manage_items? current_user.roles(cocina_object.administrative.hasAdminPolicy)
    end

    can :manage_desc_metadata, Cocina::Models::AdminPolicy do |cocina_admin_policy|
      can_edit_desc_metadata? current_user.roles(cocina_admin_policy.externalIdentifier)
    end

    can :manage_desc_metadata, [Cocina::Models::Collection, Cocina::Models::DRO] do |cocina_object|
      can_edit_desc_metadata? current_user.roles(cocina_object.administrative.hasAdminPolicy)
    end

    can :manage_governing_apo, [Cocina::Models::Collection, Cocina::Models::DRO] do |cocina_object, new_apo_id|
      # user must have management privileges on both the target APO and the APO currently governing the item
      can_manage_items?(current_user.roles(new_apo_id)) && can?(:manage_item, cocina_object)
    end

    can :view_content, Cocina::Models::DRO do |cocina_item|
      can_view? current_user.roles(cocina_item.administrative.hasAdminPolicy)
    end

    can :view_metadata, [Cocina::Models::Collection, Cocina::Models::DRO] do |cocina_object|
      can_view? current_user.roles(cocina_object.administrative.hasAdminPolicy)
    end

    can :view_metadata, Cocina::Models::AdminPolicy do |cocina_admin_policy|
      can_view?(current_user.roles(cocina_admin_policy.externalIdentifier)) ||
        can_view?(current_user.roles(cocina_admin_policy.administrative.hasAdminPolicy))
    end
  end

  # Returns true if they have been granted permission to update all workflows or
  # The status is currently "waiting" and they can manage that item
  def can_update_workflow?(status, cocina_object)
    can?(:update, :workflow) ||
      (status == 'waiting' && can?(:manage_item, cocina_object))
  end

  private

  GROUPS_WHICH_MANAGE_ITEMS = %w[dor-administrator sdr-administrator dor-apo-manager dor-apo-depositor].freeze
  GROUPS_WHICH_EDIT_DESC_METADATA = (GROUPS_WHICH_MANAGE_ITEMS + %w[dor-apo-metadata]).freeze
  GROUPS_WHICH_VIEW = (GROUPS_WHICH_MANAGE_ITEMS + %w[dor-viewer sdr-viewer]).freeze

  def can_manage_items?(roles)
    intersect roles, GROUPS_WHICH_MANAGE_ITEMS
  end

  def can_edit_desc_metadata?(roles)
    intersect roles, GROUPS_WHICH_EDIT_DESC_METADATA
  end

  def can_view?(roles)
    intersect roles, GROUPS_WHICH_VIEW
  end

  def intersect(arr1, arr2)
    !(arr1 & arr2).empty?
  end

  # A current_user who isn't logged in
  def guest_user
    User.new
  end
end

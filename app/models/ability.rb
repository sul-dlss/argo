class Ability
  include CanCan::Ability

  def initialize(user)
    user ||= User.new

    can :manage, :all if user.is_admin?
    cannot :impersonate, User unless user.is_webauth_admin?

    can [:manage_item, :manage_content, :manage_desc_metadata, :view_content, :view_metadata], ActiveFedora::Base if user.is_manager?
    can :create, Dor::AdminPolicyObject if user.is_manager?

    can [:view_metadata, :view_content], ActiveFedora::Base if user.is_viewer?

    can :manage_item, Dor::AdminPolicyObject do |dor_item|
      dor_item.can_manage_item? user.roles(dor_item.pid)
    end

    can :manage_content, Dor::AdminPolicyObject do |dor_item|
      dor_item.can_manage_content? user.roles(dor_item.pid)
    end

    can :manage_desc_metadata, Dor::AdminPolicyObject do |dor_item|
      dor_item.can_manage_desc_metadata? user.roles(dor_item.pid)
    end

    can :manage_item, ActiveFedora::Base do |dor_item|
      if dor_item.admin_policy_object
        dor_item.can_manage_item? user.roles(dor_item.admin_policy_object.pid)
      end
    end

    can :manage_content, ActiveFedora::Base do |dor_item|
      if dor_item.admin_policy_object
        dor_item.can_manage_content? user.roles(dor_item.admin_policy_object.pid)
      end
    end

    can :manage_desc_metadata, ActiveFedora::Base do |dor_item|
      if dor_item.admin_policy_object
        dor_item.can_manage_desc_metadata? user.roles(dor_item.admin_policy_object.pid)
      end
    end

    can :view_content, Dor::AdminPolicyObject do |dor_item|
      dor_item.can_view_content? user.roles(dor_item.pid)
    end

    can :view_metadata, Dor::AdminPolicyObject do |dor_item|
      dor_item.can_view_metadata? user.roles(dor_item.pid)
    end

    can :view_content, ActiveFedora::Base do |dor_item|
      if dor_item.admin_policy_object
        dor_item.can_view_content? user.roles(dor_item.admin_policy_object.pid)
      end
    end

    can :view_metadata, ActiveFedora::Base do |dor_item|
      if dor_item.admin_policy_object
        dor_item.can_view_metadata? user.roles(dor_item.admin_policy_object.pid)
      end
    end
  end
end

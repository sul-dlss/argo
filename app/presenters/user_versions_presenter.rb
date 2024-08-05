# frozen_string_literal: true

# Displays user versions for an object
class UserVersionsPresenter
  # @param [String,nil] user_version the user version of the object to display
  # @param [Array<Dor::Services::Client::UserVersion::Version>] user_version_inventory the user version inventory
  def initialize(user_version_view:, user_version_inventory:)
    @user_version_view = user_version_view&.to_i
    @user_version_inventory = user_version_inventory || []
  end

  # @param [String] version the object version
  # @return [String, nil] the user version for the given object version or nil if not found
  def user_version_for(version)
    user_version_inventory.find { |user_version_data| user_version_data.version.to_i == version.to_i }&.userVersion
  end

  # @param [Boolean] true if there is no user version or the user version is found in the inventory
  def valid_user_version?
    user_version_view.nil? || user_version_data_for(user_version_view).present?
  end

  # @param [Boolean] true if the current user version is withdrawable
  def user_version_withdrawable?
    return false unless user_version_data

    user_version_data.withdrawable?
  end

  # @param [Boolean] true if the current user version is withdrawable
  def user_version_restorable?
    return false unless user_version_data

    user_version_data.restorable?
  end

  def head_user_version
    @head_user_version ||= user_version_inventory.max_by { |user_version_data| user_version_data.userVersion.to_i }&.userVersion&.to_i
  end

  # The version for the user version view
  def version_view
    user_version_data_for(user_version_view)&.version&.to_i
  end

  attr_reader :user_version_view, :user_version_inventory

  private

  def user_version_data
    @user_version_data ||= user_version_data_for(user_version_view)
  end

  def user_version_data_for(user_version)
    user_version_inventory.find { |user_version_data| user_version_data.userVersion.to_i == user_version.to_i }
  end
end

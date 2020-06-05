# frozen_string_literal: true

# Logic for presenting the home page text
class HomeTextPresenter
  def initialize(current_user)
    @current_user = current_user
    @primary_messages = []
    @secondary_messages = []
  end

  # @return [Boolean] true if this user has permissions to see anything in Argo
  def view_something?
    admin? || manager? || viewer? || permitted_apos.any?
  end

  attr_accessor :primary_messages, :secondary_messages

  private

  attr_reader :current_user

  delegate :admin?, :manager?, :viewer?, :permitted_apos, to: :current_user
end

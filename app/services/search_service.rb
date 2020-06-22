# frozen_string_literal: true

# TODO: this class can be removed when blacklight 7.1 is installed
class SearchService < Blacklight::SearchService
  # @param scope [Object] typically the controller instance
  # @param context [User] the current user
  def initialize(config:, user_params: {}, search_builder_class: config.search_builder_class, **context)
    @blacklight_config = config
    @user_params = user_params
    @search_builder_class = search_builder_class
    @context = context
  end

  attr_reader :context
end

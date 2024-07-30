# frozen_string_literal: true

module Contents
  class StacksLinkComponent < ApplicationComponent
    include ItemsHelper

    def initialize(druid:, user_version:, cocina_file:)
      @druid = druid
      @cocina_file = cocina_file
      @user_version = user_version
    end

    attr_reader :druid, :cocina_file

    def render?
      cocina_file.administrative.shelve
    end

    def no_download?
      cocina_file.access.download == 'none'
    end

    delegate :filename, to: :cocina_file

    def stacks_link
      stacks_url_full_size(druid, filename, user_version: @user_version)
    end
  end
end

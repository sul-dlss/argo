# frozen_string_literal: true

class VersionMilestonesComponent < ViewComponent::Base
  def initialize(version:, title:, steps:)
    @version = version
    @title = title
    @steps = steps
  end

  attr_reader :version, :title, :steps
end

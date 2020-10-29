# frozen_string_literal: true

class TechmdComponent < ViewComponent::Base
  # @params [Dry::Result] result
  def initialize(result:)
    @wrapped_result = result
  end

  attr_reader :wrapped_result

  delegate :failure?, to: :wrapped_result

  def failure_message
    wrapped_result.failure
  end

  def results?
    results.present?
  end

  def results
    wrapped_result.value!
  end
end

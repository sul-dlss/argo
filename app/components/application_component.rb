# frozen_string_literal: true

class ApplicationComponent < ViewComponent::Base
  delegate :can?, to: :controller
end

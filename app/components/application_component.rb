# frozen_string_literal: true

class ApplicationComponent < ViewComponent::Base
  delegate :can?, :search_state, to: :controller
end

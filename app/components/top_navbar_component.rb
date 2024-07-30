# frozen_string_literal: true

class TopNavbarComponent < Blacklight::TopNavbarComponent
  delegate :current_user, :can?, to: :helpers
end

# frozen_string_literal: true

class ApplicationComponent < ViewComponent::Base
  delegate :can?, to: :controller
  delegate :search_state, to: :view_context

  def inspect
    "#<#{self.class.name}:#{object_id}>"
  end
end

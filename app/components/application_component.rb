# frozen_string_literal: true

class ApplicationComponent < ActionView::Component::Base
  delegate :can?, to: :controller
end

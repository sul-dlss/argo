# frozen_string_literal: true

# See https://github.com/github/actionview-component/issues/15#issuecomment-523433555
# https://github.com/github/actionview-component/pull/28/files
class ApplicationComponent < ActionView::Component::Base
  include ActiveSupport::Configurable
  include ActionController::RequestForgeryProtection

  def render_in(view_context, *args, &block)
    # Enable button_to/forms in components
    self.controller = view_context.controller
    # Enable partials to be rendered in components
    @view_renderer ||= view_context.view_renderer
    @lookup_context ||= view_context.lookup_context
    super
  end

  delegate :can?, to: :controller
end

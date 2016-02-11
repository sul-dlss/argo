# Helper methods for BulkAction views.
module BulkActionHelper
  # Renders the partial for a BulkAction based on its action type (descriptive metadata download etc.)
  def render_bulk_action_type(bulk_action)
    render partial: bulk_action.action_type.underscore, locals: {bulk_action: bulk_action}
  rescue ActionView::MissingTemplate
    render partial: 'default'
  end
end

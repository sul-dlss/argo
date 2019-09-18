# frozen_string_literal: true

# Helper methods for BulkAction views.
module BulkActionHelper
  # Renders the partial for a BulkAction based on its action type (descriptive metadata download etc.)
  def render_bulk_action_type(bulk_action)
    render partial: bulk_action.action_type.underscore, locals: { bulk_action: bulk_action }
  rescue ActionView::MissingTemplate
    render partial: 'default'
  end

  ##
  # Add a pids_only=true parameter to create a "search of pids" to an existing
  # Blacklight::Search
  # This is used by the "Populate with previous search" feature of bulk actions
  # @param [Blacklight::Search, nil]
  # @return [Hash]
  def search_of_pids(search)
    return '' unless search.present?

    search.query_params.merge('pids_only' => true)
  end

  def show_report_link?(bulk_action, filename)
    bulk_action&.status == 'Completed' && File.exist?(File.join(bulk_action.output_directory, filename))
  end
end

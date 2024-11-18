# frozen_string_literal: true

class ApplicationComponent < ViewComponent::Base
  delegate :can?, to: :controller
  delegate :search_state, to: :view_context

  def inspect
    "#<#{self.class.name}:#{object_id}>"
  end

  def allow_skip_or_complete?(workflow_step)
    %w[sdr-ingest-transfer sdr-ingest-received].exclude?(workflow_step)
  end
end

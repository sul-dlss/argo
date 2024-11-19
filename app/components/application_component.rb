# frozen_string_literal: true

class ApplicationComponent < ViewComponent::Base
  delegate :can?, to: :controller
  delegate :search_state, to: :view_context

  def inspect
    "#<#{self.class.name}:#{object_id}>"
  end

  # this is used by the WorkFlowUpdateButton and the WorklowStepStatusSelect components
  # to determine if the user is allowed to skip or complete a particular workflow step
  # (because we do not want to allow the user to manually skip or complete some steps)
  # see https://github.com/sul-dlss/argo/issues/4670
  def allow_skip_or_complete?(workflow_step)
    %w[sdr-ingest-transfer sdr-ingest-received].exclude?(workflow_step)
  end
end

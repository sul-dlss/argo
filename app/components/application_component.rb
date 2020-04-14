# frozen_string_literal: true

class ApplicationComponent < ViewComponent::Base
  delegate :can?, to: :controller
  delegate :search_state, to: :view_context

  # rotate_facet_params and facet_order is from blacklight-hierarchy
  delegate :rotate_facet_params, :facet_order, to: :view_context
end

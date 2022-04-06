# frozen_string_literal: true

require 'reform/form/coercion'

module HasViewAccessWithCdl
  extend ActiveSupport::Concern

  included do
    include HasViewAccess
    feature Reform::Form::Coercion # Casts properties to a specific type
    property :controlled_digital_lending, virtual: true, type: Dry::Types['params.nil'] | Dry::Types['params.bool']
  end

  def setup_view_access_with_cdl_properties(access_model)
    setup_view_access_properties(access_model)
    self.controlled_digital_lending = access_model.controlledDigitalLending
  end
end

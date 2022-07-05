# frozen_string_literal: true

class AccessTemplate
  include ActiveModel::API
  def initialize(access_template:, apo_defaults_template:)
    @cocina_access_template = access_template
    @apo_defaults = apo_defaults_template
  end

  attr_reader :cocina_access_template, :apo_defaults

  def default_view?(access)
    apo_defaults.view == access
  end

  def view_access
    cocina_access_template.view
  end

  def default_download?(access)
    apo_defaults.download == access
  end

  def download_access
    cocina_access_template.download
  end

  def default_location?(location)
    apo_defaults.location == location
  end

  def access_location
    cocina_access_template.location
  end

  def default_controlled_digital_lending?(cdl)
    apo_defaults.controlledDigitalLending == cdl
  end

  def controlled_digital_lending
    cocina_access_template.controlledDigitalLending
  end
end

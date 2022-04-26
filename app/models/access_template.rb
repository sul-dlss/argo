# frozen_string_literal: true

class AccessTemplate
  include ActiveModel::API
  def initialize(cocina_access_template)
    @cocina_access_template = cocina_access_template
  end

  attr_reader :cocina_access_template

  def view_access
    cocina_access_template.view
  end

  def download_access
    cocina_access_template.download
  end

  def access_location
    cocina_access_template.location
  end

  def controlled_digital_lending
    cocina_access_template.controlledDigitalLending
  end
end

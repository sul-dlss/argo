# frozen_string_literal: true

# @abstract
class ApplicationModel
  include ActiveModel::Dirty
  include ActiveModel::API

  def self.attribute(name)
    define_method name do
      instance_variable_get(:"@#{name}")
    end

    define_method :"#{name}=" do |val|
      send(:"#{name}_will_change!") unless val == instance_variable_get(:"@#{name}")
      instance_variable_set(:"@#{name}", val)
    end
  end

  def initialize(cocina = nil)
    @model = cocina
    setup_properties!
    clear_changes_information
  end

  # The original cocina data
  attr_reader :model

  def persisted?
    id.present?
  end
end

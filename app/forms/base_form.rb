# frozen_string_literal: true

# Inspired by Reform, but not exactly reform, because of existing deficiencies
# in dor-services:
#  https://github.com/sul-dlss/dor-services/pull/360
# This is the base class of all form objects
# @abstract
class BaseForm
  attr_reader :errors, :model, :params

  # @param [Dor::Item] the object to update.
  def initialize(model)
    @model = model
    @errors = model.errors
  end

  # @param [HashWithIndifferentAccess] params the parameters from the form
  # @return [Boolean] true if the parameters are valid
  def validate(params)
    @params = params
    @errors.empty?
  end

  def save
    sync
    model.save
  end

  def sync
    model.attributes = params
  end

  delegate :model_name, :to_key, :to_model, :new_record?, to: :model
end

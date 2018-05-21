# Inspired by Reform, but not exactly reform, because of existing deficiencies
# in dor-services:
#  https://github.com/sul-dlss/dor-services/pull/360
# This is the base class of all form objects
# @abstract
class BaseForm
  attr_reader :errors, :model, :params

  # @param [Dor::Item] the object to update.
  def initialize(model = nil)
    @model = model
    @errors = [] # assume no errors yet
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

  # We could delegate this to model if we solved https://github.com/sul-dlss/dor-services/pull/360
  def new_record?
    model.nil?
  end
end

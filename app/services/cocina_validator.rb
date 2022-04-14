# frozen_string_literal: true

# Creates a updated instance of the model and handles validations
class CocinaValidator
  extend Dry::Monads[:result]

  def self.validate(model, **args)
    Success(model.new(args))
  rescue Cocina::Models::ValidationError => e
    Failure(e.message)
  end
end

# frozen_string_literal: true

# Creates a updated instance of the model and handles validations
class CocinaValidator
  include Dry::Monads[:try]
  extend Dry::Monads[:result]

  def self.validate(model, **args)
    Try[Cocina::Models::ValidationError] { model.new(args) }
      .to_result
      .or { |exception| Failure([exception.message]) }
  end

  def self.validate_and_save(model, **args)
    validate(model, **args).bind do |updated|
      Try[Dor::Services::Client::UnexpectedResponse] { Repository.store(updated) }
        .to_result
        .or { |e| Failure(e.errors.pluck('detail')) }
    end
  end
end

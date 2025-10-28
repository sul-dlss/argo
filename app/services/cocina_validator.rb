# frozen_string_literal: true

# Creates a updated instance of the model and handles validations
class CocinaValidator
  include Dry::Monads[:try]
  extend Dry::Monads[:result]

  def self.validate(model, **)
    Try[Cocina::Models::ValidationError] { model.new(**) }
      .to_result
      .or { |exception| Failure([exception.message]) }
  end

  def self.validate_and_save(model, **)
    validate(model, **).bind do |updated|
      Dor::Services::Client.objects.indexable(druid: updated.externalIdentifier, cocina: updated)

      Try[Dor::Services::Client::UnexpectedResponse] { Repository.store(updated) }
        .to_result
        .or { |e| Failure(e.errors.map { |err| err['detail'] }) }
    rescue Dor::Services::Client::UnprocessableContentError => e
      Failure(["indexing validation failed for #{updated.externalIdentifier}: #{e.message}"])
    end
  end
end

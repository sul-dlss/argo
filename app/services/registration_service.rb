# frozen_string_literal: true

class RegistrationService
  extend Dry::Monads[:result]

  # @return [Result] either the Cocina model or an error message
  def self.register(model:, workflow:, tags:)
    response = Dor::Services::Client.objects.register(params: model)

    druid = response.externalIdentifier

    WorkflowClientFactory.build.create_workflow_by_name(druid, workflow, version: '1')

    Dor::Services::Client.object(druid).administrative_tags.create(tags:) unless tags.empty?
    Success(response)
  rescue Dor::Services::Client::UnexpectedResponse => e
    Failure(e.message)
  end
end

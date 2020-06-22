# frozen_string_literal: true

class RegistrationService
  extend Dry::Monads[:result]

  # @return [Result] either the Cocina model or an error message
  def self.register(model:, workflow:, tags:)
    response = Dor::Services::Client.objects.register(params: model)

    pid = response.externalIdentifier

    WorkflowClientFactory.build.create_workflow_by_name(pid, workflow, version: '1')

    Dor::Services::Client.object(pid).administrative_tags.create(tags: tags) unless tags.empty?
    Success(response)
  rescue Cocina::Models::ValidationError => e
    Failure(e.message)
  rescue Dor::Services::Client::UnexpectedResponse => e
    Failure(e.message)
  end
end

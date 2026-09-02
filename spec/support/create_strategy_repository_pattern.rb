# frozen_string_literal: true

class CreateStategyForRepositoryPattern
  def association(runner)
    runner.run
  end

  def result(evaluation)
    result = nil
    evaluation.object.tap do |instance|
      evaluation.notify(:after_build, instance)
      evaluation.notify(:before_create, instance)
      result = evaluation.create(instance)
      # dor-services-app indexes the object it just registered with a deferred commit, so make
      #   it searchable now rather than up to five seconds from now. See SolrCommit.
      SolrCommit.commit
      evaluation.notify(:after_create, instance)
    end

    result
  end
end

FactoryBot.register_strategy(:create_for_repository, CreateStategyForRepositoryPattern)

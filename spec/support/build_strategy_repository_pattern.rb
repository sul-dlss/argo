# frozen_string_literal: true

class BuildStrategyForRepositoryPattern
  def association(runner)
    runner.run
  end

  def result(evaluation)
    result = nil
    evaluation.object.tap do |instance|
      evaluation.notify(:after_build, instance)
      evaluation.notify(:before_create, instance)
      result = instance.cocina_model
      evaluation.notify(:after_create, instance)
    end

    result
  end
end

FactoryBot.register_strategy(:build_for_repository, BuildStrategyForRepositoryPattern)

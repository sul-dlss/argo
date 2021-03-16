# frozen_string_literal: true

class CollectionMethodSender
  def initialize(cocina_request)
    @cocina_model = cocina_request
  end

  attr_reader :cocina_model

  def title=(title)
    @cocina_model = @cocina_model.new(description: { title: [{ value: title }] })
  end

  def label=(label)
    @cocina_model = @cocina_model.new(label: label)
  end
end

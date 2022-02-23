# frozen_string_literal: true

class ItemMethodSender
  def initialize(cocina_request)
    @cocina_model = cocina_request
  end

  attr_reader :cocina_model

  def title=(title)
    @cocina_model = @cocina_model.new(description: { title: [{ value: title }] })
  end

  def source_id=(source_id)
    @cocina_model = @cocina_model.new(identification: @cocina_model.identification.new(sourceId: source_id))
  end

  def collection_id=(collection_id)
    @cocina_model = @cocina_model.new(structural: Cocina::Models::DROStructural.new(isMemberOf: [collection_id]))
  end
end

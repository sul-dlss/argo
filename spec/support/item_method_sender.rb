# frozen_string_literal: true

# Used in conjunction with factories/items.rb to create a Cocina::Models::RequestDRO,
#  allowing for customization of fields/values in the immutable cocina-model.
class ItemMethodSender
  def initialize(cocina_request)
    @cocina_model = cocina_request
  end

  attr_reader :cocina_model

  # @example
  #   item = create(:persisted_item, title: 'simple title value')
  def title=(title)
    @cocina_model = @cocina_model.new(description: { title: [{ value: title }] })
  end

  # @param [Array<Hash>] title_values - an array of arbitrarily complex cocina title values
  # @example
  #   item = create(:persisted_item, title_complex: title_values)
  def title_values=(title_values)
    @cocina_model = @cocina_model.new(description: { title: title_values })
  end

  # @example
  #   item = create(:persisted_item, source_id: 'sul:M932_1623_B1_F1_001')
  def source_id=(source_id)
    @cocina_model = @cocina_model.new(identification: @cocina_model.identification.new(sourceId: source_id))
  end

  # @example
  #   item = create(:persisted_item,  collection_id: 'druid:rt923rd3423')
  def collection_id=(collection_id)
    @cocina_model = @cocina_model.new(structural: Cocina::Models::DROStructural.new(isMemberOf: [collection_id]))
  end
end

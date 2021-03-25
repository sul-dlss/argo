# frozen_string_literal: true

class ApoMethodSender
  def initialize(cocina_request)
    @cocina_model = cocina_request
  end

  attr_reader :cocina_model

  def title=(title)
    @cocina_model = @cocina_model.new(description: { title: [{ value: title }] })
  end

  def roles=(roles)
    @cocina_model = @cocina_model.new(administrative: @cocina_model.administrative.new(roles: roles))
  end
end

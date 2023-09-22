# frozen_string_literal: true

class DocumentComponent < Blacklight::DocumentComponent
  def initialize(document: nil, document_counter: nil, **kwargs)
    super
  end

  def child_component
    type = @document.object_type
    "Show::#{type.classify}Component".constantize.new(presenter: @presenter)
  end
end

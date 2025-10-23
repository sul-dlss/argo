# frozen_string_literal: true

class DocumentComponent < Blacklight::DocumentComponent
  def initialize(document: nil, **kwargs)
    super
  end

  def child_component
    component_class.new(presenter: @presenter)
  end

  def component_class
    case @document.object_type
    when 'collection'
      Show::CollectionComponent
    when 'agreement'
      Show::AgreementComponent
    when 'adminPolicy'
      Show::AdminPolicyComponent
    else
      Show::ItemComponent
    end
  end
end

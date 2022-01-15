# frozen_string_literal: true

class DocumentTitleComponent < Blacklight::DocumentTitleComponent
  def object_type
    @document.object_type == 'adminPolicy' ? 'apo' : @document.object_type
  end
end

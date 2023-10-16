# frozen_string_literal: true

# This models the component that appears when you click one of the blue buttons to modify an object.
# It does not depend on the Blacklight::System::ModalComponent, which does not use Turbo.
class EditModalComponent < ApplicationComponent
  renders_one :header
  renders_one :body
  renders_one :footer
end

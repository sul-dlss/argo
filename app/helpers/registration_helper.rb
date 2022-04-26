# frozen_string_literal: true

module RegistrationHelper
  def valid_content_types
    # the content types selectable in registration are capitalized but match what is available when setting content types
    #  in the bulk and item detail page for setting content types (exception: '3d' needs to go '3D')
    Constants::CONTENT_TYPES.keys.map { |content_type| content_type == '3d' ? '3D' : content_type.capitalize }
  end
end

# frozen_string_literal: true

# This models the component that appears when you click one of the blue buttons to modify an object.
# It does not depend on the BlacklightModalComponent, which has a bunch of jquery javascript for
# doing the ajax.  That javascript prevents us from showing errors after a form is submitted.
class EditModalComponent < ApplicationComponent
  renders_one :header
  renders_one :body
  renders_one :footer
end

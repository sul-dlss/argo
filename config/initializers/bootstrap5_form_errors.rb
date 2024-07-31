# frozen_string_literal: true

# Give any .form_control the .is-invalid Bootstrap 5 class
# html_tag is a ActiveSupport::SafeBuffer
ActionView::Base.field_error_proc = proc do |html_tag, _instance|
  html_tag.sub('form-control', 'form-control is-invalid').html_safe # rubocop:disable Rails/OutputSafety
end

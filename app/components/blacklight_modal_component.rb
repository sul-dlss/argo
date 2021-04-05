# frozen_string_literal: true

# Designed to use bootstrap styles to fill within the Blacklight modal
class BlacklightModalComponent < ViewComponent::Base
  renders_one :header
  renders_one :body
  renders_one :footer
end

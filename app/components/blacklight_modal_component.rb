# frozen_string_literal: true

# Designed to use bootstrap styles to fill within the Blacklight modal
class BlacklightModalComponent < ViewComponent::Base
  with_content_areas :header, :body, :footer
end

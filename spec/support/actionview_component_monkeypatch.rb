# frozen_string_literal: true

require 'action_view/component/test_helpers'

# See https://github.com/github/actionview-component/issues/15#issuecomment-523433555
module ActionView
  module Component
    module TestHelpers
      def controller
        @controller ||= ApplicationController.new.tap { |c| c.request = ActionDispatch::TestRequest.create }
      end

      def render_inline(component, **args, &block)
        Nokogiri::HTML(controller.view_context.render(component, args, &block))
      end
    end
  end
end

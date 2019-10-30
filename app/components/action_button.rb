# frozen_string_literal: true

# Draws a blue button in the side menu
class ActionButton < ApplicationComponent
  # @param [Hash] properties the button properties
  def initialize(label:, url:, method: nil, confirm: nil, new_page: nil, check_url: nil, disabled: nil)
    @label = label
    @url = url
    @method = method
    @confirm = confirm
    @new_page = new_page
    @check_url = check_url
    @disabled = disabled
  end

  def disabled?
    check_url || disabled
  end

  def button_data
    {}.tap do |data|
      if confirm
        # :confirm trumps :blacklight_modal, because :blacklight_modal would negate :confirm by firing the ajax request regardless of the user's decision
        data[:confirm] = confirm
      elsif !new_page
        data[:blacklight_modal] = 'trigger'
      end
      data[:check_url] = check_url if check_url
    end
  end

  attr_reader :label, :confirm, :new_page, :check_url, :url, :disabled, :method
end

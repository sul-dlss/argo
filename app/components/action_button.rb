# frozen_string_literal: true

# Draws button on the item detail page
class ActionButton < ApplicationComponent
  # @param [Hash] properties the button properties
  def initialize(label:, url:, method: nil, confirm: nil, open_modal: false, check_url: nil, disabled: nil)
    @label = label
    @url = url
    @method = method
    @confirm = confirm
    @open_modal = open_modal
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
        data[:turbo_confirm] = confirm
      elsif open_modal
        data[:action] = 'click->button#open'
      end
      data[:button_check_url_value] = check_url if check_url
      data[:controller] = 'button' if data[:action] || data[:button_check_url_value]
      data[:turbo_method] = method if method
    end
  end

  attr_reader :label, :confirm, :open_modal, :check_url, :url, :disabled, :method
end

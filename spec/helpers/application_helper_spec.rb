# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApplicationHelper do
  describe '#views_to_switch' do
    it 'returns the view switchers' do
      helper.views_to_switch.each do |view|
        expect(view).to be_an ViewSwitcher
      end
    end
  end
end

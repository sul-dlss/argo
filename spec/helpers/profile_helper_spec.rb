# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ProfileHelper do
  describe '#show_pagination?' do
    context 'when using ProfileController' do
      it 'returns false' do
        allow(helper).to receive_messages(params: { 'controller' => 'profile' })
        expect(helper.show_pagination?).to be false
      end
    end
  end
end

# frozen_string_literal: true

require 'rails_helper'

describe ProfileHelper, type: :helper do
  describe '#show_pagination?' do
    context 'when using ProfileController' do
      it 'returns false' do
        allow(helper).to receive_messages(params: { 'controller' => 'profile' })
        expect(helper.show_pagination?).to eq false
      end
    end
  end
end

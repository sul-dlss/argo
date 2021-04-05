# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Create a new Admin Policy' do
  let(:user) { create(:user) }

  before do
    sign_in user, groups: ['sdr:administrator-role']
  end

  context 'when the parameters are invalid' do
    it 'redraws the form' do
      post '/apo', params: { apo_form: { title: '' } }
      expect(response).to be_successful
    end
  end
end

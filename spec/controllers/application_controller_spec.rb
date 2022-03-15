# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApplicationController, type: :controller do
  describe '#current_user' do
    subject { controller.current_user }

    before do
      sign_in User.create(sunetid: 'bob')
    end

    it 'sets impersonated_groups if impersonation info was in the session' do
      impersonated_groups = ['workgroup:dlss:impersonatedgroup1', 'workgroup:dlss:impersonatedgroup2']
      session[:groups] = impersonated_groups
      expect(subject.groups).to eq(impersonated_groups)
    end
  end
end

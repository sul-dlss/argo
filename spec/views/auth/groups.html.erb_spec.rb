# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'auth/groups' do
  before do
    allow(view).to receive(:current_user).and_return(user)
    allow(controller).to receive(:current_user).and_return(user)
  end

  context 'as admin' do
    let(:user) { mock_user(admin?: true, sdr_api_authorized?: false, groups: %w[dlss dpg]) }

    it 'shows groups and impersonate form' do
      render
      expect(rendered).to have_css 'h3', text: 'Your Current Groups'
      expect(rendered).to have_css 'li', text: 'dlss'
      expect(rendered).to have_css 'li', text: 'dpg'
      expect(rendered).to have_css 'label', text: 'Enter a group or a comma separated list of groups to impersonate'
      expect(rendered).to have_css 'input#groups[type="text"]'
      expect(rendered).to have_css 'input[type="submit"][value="Impersonate"]'
      expect(rendered).to have_css 'a.btn.btn-outline-primary[href="javascript:history.back()"]', text: 'Cancel'
    end
  end

  context 'not as admin' do
    let(:user) { mock_user(admin?: false, sdr_api_authorized?: false) }

    it 'does not show groups or form' do
      render
      expect(rendered).to have_no_css 'h3', text: 'Your Current Groups'
      expect(rendered).to have_no_css 'form'
    end
  end
end

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'BulkActions::ManageReleaseJobs', type: :request do
  let(:rendered) do
    Capybara::Node::Simple.new(response.body)
  end

  describe 'GET #new' do
    before do
      sign_in build(:user, sunetid: 'frank'), groups: ['sdr:administrator-role']
    end

    it 'draws the form' do
      get '/bulk_actions/manage_release_job/new'

      expect(rendered).to have_css 'textarea[name="druids"]'
      expect(rendered).to have_css 'textarea[name="description"]'
      expect(rendered).to have_css 'input[type="radio"][value="true"][checked="checked"][name="tag"]'
      expect(rendered).to have_css 'input[type="radio"][value="false"][name="tag"]'
      expect(rendered).to have_css 'select[name="to"]'
      expect(rendered).to have_css 'option[value="Searchworks"]'
      expect(rendered).to have_css 'input[value="self"][type="hidden"][name="what"]', visible: :hidden
      expect(rendered).to have_css 'input[value="frank"][type="hidden"][name="who"]', visible: :hidden
    end
  end
end

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'BulkActions::CatkeyAndBarcodeJobs', type: :request do
  let(:rendered) do
    Capybara::Node::Simple.new(response.body)
  end

  describe 'GET #new' do
    before do
      sign_in build(:user), groups: ['sdr:administrator-role']
    end

    it 'draws the form' do
      get '/bulk_actions/catkey_and_barcode_job/new'

      expect(rendered).to have_css 'textarea[name="druids"]'
      expect(rendered).to have_css 'textarea[name="description"]'
      expect(rendered).to have_css 'input[type="checkbox"][value="1"][name="use_catkeys_option"]'
      expect(rendered).to have_css 'textarea[name="catkeys"]'
      expect(rendered).to have_css 'input[type="checkbox"][value="1"][name="use_barcodes_option"]'
      expect(rendered).to have_css 'textarea[name="barcodes"]'
    end
  end
end

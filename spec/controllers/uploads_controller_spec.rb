# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UploadsController do
  let(:user) { create(:user) }
  let(:apo_id) { 'abc123' }
  let(:item) { instance_double(Dor::Item, id: apo_id) }

  before do
    sign_in user
    allow(Dor).to receive(:find).and_return(item)
  end

  describe '#new' do
    it 'is successful' do
      get :new, params: { item_id: apo_id }
      expect(response).to be_successful
      expect(assigns[:obj]).to eq item
    end
  end

  describe '#create' do
    let(:file) { fixture_file_upload('crowdsourcing_bridget_1.xlsx') }

    it 'is successful' do
      expect(ModsulatorJob).to receive(:perform_later)
        .with('abc123', String, String, user.login, 'spreadsheet', 'true', 'test note')
      post :create, params: { item_id: apo_id,
                              druid: 'foo',
                              spreadsheet_file: file,
                              filetypes: 'spreadsheet',
                              xml_only: 'true',
                              note: 'test note' }
      expect(response).to redirect_to apo_bulk_jobs_path(apo_id)
    end
  end
end

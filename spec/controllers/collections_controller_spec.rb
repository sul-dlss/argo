# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CollectionsController do
  before do
    allow(Dor).to receive(:find).with(apo.pid).and_return(apo)
    allow(controller).to receive(:authorize!).with(:manage_item, Dor::AdminPolicyObject).and_return(true)
    sign_in user
  end

  let(:user) { create(:user) }
  let(:apo) { instantiate_fixture('zt570tx3016', Dor::AdminPolicyObject) }
  let(:collection) { instantiate_fixture('pb873ty1662', Dor::Collection) }

  describe '#new' do
    it 'is successful' do
      get :new, params: { apo_id: apo.pid }
      expect(assigns[:apo]).to eq apo
      expect(response).to be_successful
    end
  end

  describe '#create' do
    let(:form) { instance_double(CollectionForm, validate: true, save: true, model: collection) }

    before do
      allow(CollectionForm).to receive(:new).and_return(form)
    end

    it 'creates a collection using the form' do
      post :create, params: { 'label' => ':auto',
                              'collection_catkey' => '1234567',
                              'collection_rights_catkey' => 'dark',
                              apo_id: apo.pid }
      expect(response).to be_redirect # redirects to catalog page
      expect(form).to have_received(:save)
    end
  end

  describe '#exists' do
    let(:title) { 'foo' }
    let(:catkey) { '123' }

    it 'returns true if collection with title exists' do
      allow(Dor::Collection).to receive(:where).and_return([1])
      expect(Dor::Collection).to receive(:where).with(title_ssi: title)
      post :exists, params: {
        'title' => title
      }
      expect(response.body).to eq('true')
    end
    it 'returns false if collection with title exists' do
      allow(Dor::Collection).to receive(:where).and_return([])
      expect(Dor::Collection).to receive(:where).with(title_ssi: title)
      post :exists, params: {
        'title' => title
      }
      expect(response.body).to eq('false')
    end
    it 'returns true if collection with catkey exists' do
      allow(Dor::Collection).to receive(:where).and_return([1])
      expect(Dor::Collection).to receive(:where).with(identifier_ssim: "catkey:#{catkey}")
      post :exists, params: {
        'catkey' => catkey
      }
      expect(response.body).to eq('true')
    end
    it 'returns false if collection with catkey exists' do
      allow(Dor::Collection).to receive(:where).and_return([])
      expect(Dor::Collection).to receive(:where).with(identifier_ssim: "catkey:#{catkey}")
      post :exists, params: {
        'catkey' => catkey
      }
      expect(response.body).to eq('false')
    end
    it 'returns true if collection with title and catkey exists' do
      allow(Dor::Collection).to receive(:where).and_return([1])
      expect(Dor::Collection).to receive(:where).with(title_ssi: title, identifier_ssim: "catkey:#{catkey}")
      post :exists, params: {
        'title' => title,
        'catkey' => catkey
      }
      expect(response.body).to eq('true')
    end
  end
end

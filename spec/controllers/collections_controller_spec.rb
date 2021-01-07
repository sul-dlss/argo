# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CollectionsController do
  before do
    allow(Dor).to receive(:find).with(apo.pid).and_return(apo)
    allow(controller).to receive(:authorize!).with(:manage_item, Cocina::Models::AdminPolicy).and_return(true)
    sign_in user
  end

  let(:user) { create(:user) }
  let(:apo) { instance_double(Dor::AdminPolicyObject, pid: 'druid:zt570qh4444', add_default_collection: true, save: true) }
  let(:collection_id) { 'druid:bp475vb4486' }

  let(:collection) do
    Dor::Collection.new(pid: collection_id)
  end

  describe '#new' do
    let(:object_client) { instance_double(Dor::Services::Client::Object, find: cocina_model) }
    let(:cocina_model) do
      Cocina::Models.build(
        'label' => 'The APO',
        'version' => 1,
        'type' => Cocina::Models::Vocab.admin_policy,
        'externalIdentifier' => pid,
        'administrative' => { hasAdminPolicy: 'druid:hv992ry2431' }
      )
    end
    let(:pid) { 'druid:zt570tx3016' }

    before do
      allow(Dor::Services::Client).to receive(:object).and_return(object_client)
    end

    it 'is successful' do
      get :new, params: { apo_id: apo.pid }
      expect(assigns[:apo]).to eq apo
      expect(response).to be_successful
    end
  end

  describe '#create' do
    let(:form) { instance_double(CollectionForm, validate: true, save: true, model: collection) }
    let(:object_client) { instance_double(Dor::Services::Client::Object, find: cocina_model) }
    let(:cocina_model) do
      Cocina::Models.build(
        'label' => 'The APO',
        'version' => 1,
        'type' => Cocina::Models::Vocab.admin_policy,
        'externalIdentifier' => pid,
        'administrative' => { hasAdminPolicy: 'druid:hv992ry2431' }
      )
    end
    let(:pid) { 'druid:zt570tx3016' }

    before do
      allow(Dor::Services::Client).to receive(:object).and_return(object_client)
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

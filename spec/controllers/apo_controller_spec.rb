# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApoController, type: :controller do
  before do
    allow(Dor::Services::Client).to receive(:object).and_return(object_client)

    allow(Dor).to receive(:find).with(apo.pid).and_return(apo)
    allow(apo).to receive(:save)

    allow(Dor).to receive(:find).with(collection.externalIdentifier).and_return(collection)
    allow(collection).to receive(:save)

    sign_in user
    allow(controller).to receive(:authorize!).with(:manage_item, Cocina::Models::AdminPolicy).and_return(true)
  end

  let(:user) { create(:user) }
  let(:apo) { instance_double(Dor::AdminPolicyObject, pid: pid) }
  let(:pid) { 'druid:zt570qh4444' }
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

  let(:collection_id) { 'druid:bq377wp9578' }
  let(:collection) do
    Cocina::Models::Collection.new(externalIdentifier: collection_id,
                                   type: Cocina::Models::Vocab.collection,
                                   label: '',
                                   version: 1,
                                   access: {})
  end

  describe '#create' do
    let(:form) do
      instance_double(ApoForm, validate: valid,
                               save: true,
                               model: apo,
                               default_collection_pid: nil)
    end

    before do
      allow(ApoForm).to receive(:new).and_return(form)
      allow(controller).to receive(:authorize!).with(:create, Dor::AdminPolicyObject).and_return(true)
    end

    context 'when the form is valid' do
      let(:valid) { true }

      it 'is successful' do
        post :create, params: {}
        expect(form).to have_received(:validate).with(ActionController::Parameters)
        expect(response).to be_redirect
        expect(flash[:notice]).to eq 'APO druid:zt570qh4444 created.'
      end
    end

    context 'when the form is invalid' do
      let(:valid) { false }

      it 'redraws the form' do
        post :create, params: {}
        expect(form).to have_received(:validate).with(ActionController::Parameters)
        expect(response).to render_template 'new'
        expect(assigns[:form]).to eq form
      end
    end
  end

  describe '#update' do
    let(:form) do
      instance_double(ApoForm, validate: valid,
                               save: true,
                               model: apo,
                               default_collection_pid: nil)
    end

    before do
      allow(ApoForm).to receive(:new).and_return(form)
      allow(controller).to receive(:authorize!).with(:create, Dor::AdminPolicyObject).and_return(true)
    end

    context 'when the form is valid' do
      let(:valid) { true }

      it 'is successful' do
        patch :update, params: { id: apo.pid }
        expect(form).to have_received(:validate).with(ActionController::Parameters)
        expect(response).to be_redirect
      end
    end

    context 'when the form is invalid' do
      let(:valid) { false }

      it 'redraws the form' do
        patch :update, params: { id: apo.pid }
        expect(form).to have_received(:validate).with(ActionController::Parameters)
        expect(response).to render_template 'edit'
        expect(assigns[:form]).to eq form
      end
    end
  end

  describe '#delete_collection' do
    it 'calls remove_default_collection' do
      expect(apo).to receive(:remove_default_collection)
      post 'delete_collection', params: { id: apo.pid, collection: collection.externalIdentifier }
    end
  end
end

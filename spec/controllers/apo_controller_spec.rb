# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApoController, type: :controller do
  before do
    allow(Dor).to receive(:find).with(apo.pid).and_return(apo)
    allow(apo).to receive(:save)

    allow(Dor).to receive(:find).with(collection.externalIdentifier).and_return(collection)
    allow(collection).to receive(:save)

    sign_in user
    allow(controller).to receive(:authorize!).with(:manage_item, Dor::AdminPolicyObject).and_return(true)
  end

  let(:user) { create(:user) }

  let(:apo) { instantiate_fixture('zt570tx3016', Dor::AdminPolicyObject) }
  let(:collection) { FactoryBot.create_for_repository(:collection) }

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
        expect(flash[:notice]).to eq 'APO druid:zt570tx3016 created.'
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

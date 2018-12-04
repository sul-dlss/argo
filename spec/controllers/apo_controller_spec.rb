# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ApoController, type: :controller do
  before do
    allow(Dor).to receive(:find).with(apo.pid).and_return(apo)
    allow(apo).to receive(:save)

    allow(Dor).to receive(:find).with(collection.pid).and_return(collection)
    allow(collection).to receive(:save)
    allow(controller).to receive(:update_index)

    sign_in user
    allow(controller).to receive(:authorize!).with(:manage_item, Dor::AdminPolicyObject).and_return(true)
  end

  let(:user) { create(:user) }

  let(:apo) { instantiate_fixture('zt570tx3016', Dor::AdminPolicyObject) }
  let(:collection) { instantiate_fixture('pb873ty1662', Dor::Collection) }

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

  describe '#add_roleplayer' do
    it 'adds a roleplayer' do
      expect(apo).to receive(:add_roleplayer)
      post 'add_roleplayer', params: { id: apo.pid, role: 'dor-apo-viewer', roleplayer: 'Jon' }
    end
  end

  describe '#delete_role' do
    it 'calls delete_role' do
      expect(apo).to receive(:delete_role)
      post 'delete_role', params: { id: apo.pid, role: 'dor-apo-viewer', entity: 'Jon' }
    end
  end

  describe '#delete_collection' do
    it 'calls remove_default_collection' do
      expect(apo).to receive(:remove_default_collection)
      post 'delete_collection', params: { id: apo.pid, collection: collection.pid }
    end
  end

  describe '#add_collection' do
    it 'calls add_default_collection' do
      expect(apo).to receive(:add_default_collection)
      post 'add_collection', params: { id: apo.pid, collection: collection.pid }
    end
  end

  describe '#update_title' do
    it 'calls set_title' do
      expect(apo).to receive(:mods_title=)
      post 'update_title', params: { id: apo.pid, title: 'awesome new title' }
    end
  end

  describe '#update_creative_commons' do
    it 'sets creative_commons' do
      expect(apo).to receive(:creative_commons_license=)
      expect(apo).to receive(:creative_commons_license_human=)
      post 'update_creative_commons', params: { id: apo.pid, cc_license: 'by-nc' }
    end
  end

  describe '#update_use' do
    it 'calls set_use_statement' do
      expect(apo).to receive(:use_statement=)
      post 'update_use', params: { id: apo.pid, use: 'new use statement' }
    end
  end

  describe '#update_copyight' do
    it 'calls set_copyright_statement' do
      expect(apo).to receive(:copyright_statement=)
      post 'update_copyright', params: { id: apo.pid, copyright: 'new copyright statement' }
    end
  end

  describe '#update_default_object_rights' do
    it 'calls set_default_rights' do
      expect(apo).to receive(:default_rights=)
      post 'update_default_object_rights', params: { id: apo.pid, rights: 'stanford' }
    end
  end

  describe '#update_desc_metadata' do
    it 'calls set_desc_metadata_format' do
      expect(apo).to receive(:desc_metadata_format=)
      post 'update_desc_metadata', params: { id: apo.pid, desc_md: 'TEI' }
    end
  end
end

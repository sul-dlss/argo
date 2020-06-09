# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'catalog/ds.html.erb' do
  let(:stub_ds) { instance_double(Dor::IdentityMetadataDS, content: '<xml />') }

  before do
    params[:dsid] = dsid
    params[:id] = 'druid:abc123'
    allow(view).to receive(:can?).and_return(true)
    allow(view).to receive(:render_ds_profile_header)
    @obj = instance_double(Dor::Item, datastreams: { dsid => stub_ds })
  end

  context 'with an editable datastream' do
    let(:dsid) { 'identityMetadata' }

    it 'renders the modal with edit link' do
      render
      expect(rendered).to have_css '.modal-header h3.modal-title'
      expect(rendered).to have_css '.modal-body'
      expect(rendered).to include 'Edit identityMetadata'
    end
  end

  context 'with an non-editable datastream' do
    let(:dsid) { 'fakeMetadata' }

    it 'renders the modal without the edit link' do
      render
      expect(rendered).to have_css '.modal-header h3.modal-title'
      expect(rendered).to have_css '.modal-body'
      expect(rendered).not_to include 'Edit fakeMetadata'
    end
  end
end

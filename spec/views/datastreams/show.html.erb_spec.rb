# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'datastreams/show' do
  before do
    params[:id] = dsid
    allow(view).to receive(:can?).and_return(true)
    @cocina = build(:dro)
    @content = '<identityMetadata></identityMetadata>'
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

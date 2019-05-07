# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'catalog/ds.html.erb' do
  let(:dsid) { 'identityMetadata' }
  let(:stub_ds) { instance_double(Dor::IdentityMetadataDS, content: '<xml />') }

  before do
    params[:dsid] = dsid
    allow(view).to receive(:can?).and_return(true)
    allow(view).to receive(:render_ds_profile_header)
    @obj = instance_double(Dor::Item, datastreams: { dsid => stub_ds })
  end

  it 'renders the modal' do
    render
    expect(rendered).to have_css '.modal-header h3.modal-title'
    expect(rendered).to have_css '.modal-body', text: '<xml/>'
  end
end

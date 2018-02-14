require 'spec_helper'

RSpec.describe 'catalog/ds.html.erb' do
  it 'renders the JS template' do
    controller.request.path_parameters[:dsid] = 'identityMetadata'
    stub_template 'catalog/_ds.html.erb' => 'stubbed_ds'
    render
    expect(rendered).to have_css '.modal-header h3.modal-title'
    expect(rendered).to have_css '.modal-body', text: 'stubbed_ds'
  end
end

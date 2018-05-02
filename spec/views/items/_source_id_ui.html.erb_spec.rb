require 'spec_helper'

RSpec.describe 'items/_source_id_ui.html.erb' do
  let(:identity_metadata) { double('idmd', sourceId: 'source id') }
  let(:object) do
    double('object', pid: 'druid:abc123', identityMetadata: identity_metadata)
  end
  it 'renders the partial content' do
    assign(:object, object)
    render
    expect(rendered)
      .to have_css 'form .form-group input.form-control[value="source id"]'
    expect(rendered).to have_css 'p.help-block'
    expect(rendered).to have_css 'button.btn.btn-primary', text: 'Update'
  end
end

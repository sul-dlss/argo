require 'spec_helper'

RSpec.describe 'items/purl_preview.js.erb' do
  let(:mods_display) { double('mods', title: ['Cool Catz']) }
  it 'renders the JS template' do
    expect(view).to receive(:render_mods_display).and_return mods_display
    stub_template 'items/_purl_preview.html.erb' => 'stubbed_purl_preview'
    render
    expect(rendered)
      .to have_css '.modal-header h3.modal-title', text: 'Cool Catz'
    expect(rendered).to have_css '.modal-body', text: 'stubbed_purl_preview'
  end
end

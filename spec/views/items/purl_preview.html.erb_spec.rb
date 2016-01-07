require 'spec_helper'

RSpec.describe 'items/purl_preview.html.erb' do
  let(:mods_display) { double('mods', title: ['Cool Catz']) }
  it 'renders the HTML template' do
    expect(view).to receive(:render_mods_display).and_return mods_display
    stub_template 'items/_purl_preview.html.erb' => 'stubbed_purl_preview'
    render
    expect(rendered).to have_css '.container h1', text: 'Cool Catz'
    expect(rendered).to have_css '.container', text: 'stubbed_purl_preview'
  end
end

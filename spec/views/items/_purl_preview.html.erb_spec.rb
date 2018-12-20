# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'items/_purl_preview.html.erb' do
  let(:mods_display) { double('mods', body: 'Cool Catz') }

  it 'renders the partial content' do
    expect(view).to receive(:render_mods_display).and_return(mods_display)
    render
    expect(rendered).to have_content 'Cool Catz'
  end
end

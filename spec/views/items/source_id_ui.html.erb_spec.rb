# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'items/source_id_ui' do
  it 'renders the template' do
    stub_template 'items/_source_id_ui.html.erb' => 'stubbed_source_id_ui'
    render
    expect(rendered)
      .to have_css '.modal-header h3.modal-title', text: 'Change source id'
    expect(rendered).to have_css '.modal-body', text: 'source_id_ui'
  end
end

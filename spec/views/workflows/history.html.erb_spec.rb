# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'workflows/history' do
  it 'renders the HS template' do
    stub_template 'workflows/_history.html.erb' => 'stubbed_wf_history_view'
    render
    expect(rendered).to have_css '.modal-header h3.modal-title', text: 'Workflow history'
    expect(rendered).to have_css '.modal-body', text: 'stubbed_wf_history_view'
  end
end

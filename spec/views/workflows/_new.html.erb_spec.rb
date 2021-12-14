# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'workflows/_new.html.erb' do
  before do
    allow(view).to receive(:workflow_options).and_return([%w[assemblyWF assemblyWF], %w[registrationWF registrationWF]])
  end

  it 'renders the partial content' do
    controller.request.path_parameters[:item_id] = 'test'
    render
    expect(rendered).to have_css 'form select'
    expect(rendered).to have_css 'form button.btn.btn-primary', text: 'Add'
  end
end

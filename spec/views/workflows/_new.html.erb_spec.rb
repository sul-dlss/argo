# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'workflows/_new.html.erb' do
  it 'renders the partial content' do
    controller.request.path_parameters[:item_id] = 'test'
    render
    expect(rendered).to have_css 'form .form-group select'
    expect(rendered).to have_css 'form button.btn.btn-primary', text: 'Add'
  end
end

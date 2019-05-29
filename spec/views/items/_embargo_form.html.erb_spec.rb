# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'items/_embargo_form.html.erb' do
  let(:current_user) { mock_user(is_admin?: true) }

  before do
    allow(view).to receive(:current_user).and_return(current_user)
    allow(controller).to receive(:current_user).and_return(current_user)
  end

  # let(:object) { double('object', pid: 'druid:abc123')}
  it 'renders the partial content' do
    controller.request.path_parameters[:id] = 'test'
    render
    expect(rendered).to have_css 'form .form-group label', text: 'New date'
    expect(rendered).to have_css 'input#embargo_date'
    expect(rendered)
      .to have_css 'button.btn.btn-primary', text: 'Update Embargo'
  end
end

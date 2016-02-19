require 'spec_helper'

RSpec.describe 'items/_embargo_form.html.erb' do
  let(:current_user) do
    double('current_user', is_admin: true)
  end
  # let(:object) { double('object', pid: 'druid:abc123')}
  it 'renders the partial content' do
    controller.request.path_parameters[:id] = 'test'
    expect(view).to receive(:current_user).and_return(current_user).twice
    render
    expect(rendered).to have_css 'form .form-group label', text: 'New date'
    expect(rendered).to have_css 'input#embargo_date'
    expect(rendered)
      .to have_css 'button.btn.btn-primary', text: 'Update Embargo'
  end
end

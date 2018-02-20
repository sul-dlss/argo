require 'spec_helper'

RSpec.describe 'content_types/show.html.erb' do
  it 'renders the template' do
    stub_template 'content_types/_content_type.html.erb' => 'stubbed_content_type'
    render
    expect(rendered).to have_css '.modal-header h3.modal-title', text: 'Set content type'
    expect(rendered).to have_css '.modal-body', text: 'stubbed_content_type'
  end
end

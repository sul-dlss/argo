# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'items/_tags_ui.html.erb' do
  let(:object) do
    double('object', pid: 'druid:abc123', tags: ['Catz are awesome', 'Nice!'])
  end

  it 'renders the partial content' do
    assign(:object, object)
    render
    expect(rendered).to have_css 'form[action="/items/druid:abc123/tags?update=true"]'
    expect(rendered).to have_css '.form-group .input-group input.form-control[value="Catz are awesome"]'
    expect(rendered).to have_css '.form-group .input-group input.form-control[value="Nice!"]'
    expect(rendered).to have_css 'button.btn.btn-primary', text: 'Update'
    expect(rendered).to have_css 'form[action="/items/druid:abc123/tags?add=true"]'
    expect(rendered).to have_css 'button.btn.btn-primary', text: 'Add'
  end
end

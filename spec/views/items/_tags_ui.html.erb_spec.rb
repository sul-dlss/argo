# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'items/_tags_ui.html.erb' do
  let(:pid) { 'druid:bc123df5678' }
  let(:tags) { ['Catz are awesome', 'Nice!'] }

  it 'renders the partial content' do
    assign(:pid, pid)
    assign(:tags, tags)
    render
    expect(rendered).to have_css 'form[action="/items/druid:bc123df5678/tags?update=true"]'
    expect(rendered).to have_css '.form-group .input-group input.form-control[value="Catz are awesome"]'
    expect(rendered).to have_css '.form-group .input-group input.form-control[value="Nice!"]'
    expect(rendered).to have_css 'button.btn.btn-primary', text: 'Update'
    expect(rendered).to have_css 'form[action="/items/druid:bc123df5678/tags?add=true"]'
    expect(rendered).to have_css 'button.btn.btn-primary', text: 'Add'
  end
end

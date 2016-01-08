require 'spec_helper'

RSpec.describe 'items/_workflow_history_view.html.erb' do
  it 'renders the partial content' do
    render
    expect(rendered).to have_css '.CodeRay'
  end
end

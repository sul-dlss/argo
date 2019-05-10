# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'workflows/_history.html.erb' do
  it 'renders the partial content' do
    render
    expect(rendered).to have_css '.CodeRay'
  end
end

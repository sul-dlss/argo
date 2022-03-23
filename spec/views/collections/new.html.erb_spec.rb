# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'collections/new', type: :view do
  it 'renders the HTML template form' do
    @item = build(:admin_policy)
    render
    expect(rendered).to have_field 'collection_title'
    expect(rendered).to have_field 'collection_abstract'
    expect(rendered).to have_field 'collection_rights'
    expect(rendered).to have_field 'collection_catkey', visible: false
    expect(rendered).to have_field 'collection_rights_catkey', visible: false
  end
end

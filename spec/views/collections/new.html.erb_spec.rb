# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'collections/new.html.erb', type: :view do
  it 'renders the HTML template form' do
    assign(:cocina, instance_double(Cocina::Models::AdminPolicy, externalIdentifier: 'druid:zt570qh4444', label: 'My label'))
    render
    expect(rendered).to have_field 'collection_title'
    expect(rendered).to have_field 'collection_abstract'
    expect(rendered).to have_field 'collection_rights'
    expect(rendered).to have_field 'collection_catkey', visible: false
    expect(rendered).to have_field 'collection_rights_catkey', visible: false
  end
end

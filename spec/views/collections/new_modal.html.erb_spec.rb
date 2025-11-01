# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'collections/new_modal' do
  it 'renders the HTML template form' do
    assign(:cocina_admin_policy,
           instance_double(Cocina::Models::AdminPolicy, externalIdentifier: 'druid:zt570qh4444', label: 'My label'))
    render
    expect(rendered).to have_field 'collection_title'
    expect(rendered).to have_field 'collection_abstract'
    expect(rendered).to have_field 'collection_rights'
    expect(rendered).to have_field 'collection_catalog_record_id', visible: :hidden
    expect(rendered).to have_field 'collection_rights_catalog_record_id', visible: :hidden
  end
end

# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'collections/new.html.erb', type: :view do
  it 'renders the HTML template form' do
    assign(:apo, double('pid' => 'druid:zt570tx3016', 'label' => 'My label'))
    render
    expect(rendered).to have_css 'form#collection_form'
    expect(rendered).to have_css 'div#create-collection'
    expect(rendered).to have_field 'collection_title'
    expect(rendered).to have_field 'collection_abstract'
    expect(rendered).to have_field 'collection_rights'
    expect(rendered).to have_css 'div#create-collection-catkey', visible: false
    expect(rendered).to have_field 'collection_catkey', visible: false
    expect(rendered).to have_field 'collection_rights_catkey', visible: false
  end
end

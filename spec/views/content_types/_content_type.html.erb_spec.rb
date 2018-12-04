# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'content_types/_content_type.html.erb' do
  let(:content_metadata) do
    double('cm', contentType: [''], ng_xml: Nokogiri::XML('<xml></xml>'))
  end
  let(:object) do
    double('object', pid: 'druid:abc123', contentMetadata: content_metadata)
  end
  it 'renders the partial content' do
    assign(:object, object)
    render
    expect(rendered).to have_css 'form .form-group label', text: 'Old content type'
    expect(rendered).to have_css 'input[type="hidden"]#old_content_type', visible: false
    expect(rendered).to have_css 'form .form-group label', text: 'Old resource type'
    expect(rendered).to have_css 'select.form-control#old_resource_type'
    expect(rendered).to have_css 'form .form-group label', text: 'New content type'
    Constants::CONTENT_TYPES.each do |type|
      expect(rendered).to have_css 'form select option', text: type
    end
    expect(rendered).to have_css 'form select option', text: 'none', count: 3
    expect(rendered).to have_css 'select.form-control#new_content_type'
    expect(rendered).to have_css 'form .form-group label', text: 'New resource type'
    expect(rendered).to have_css 'select.form-control#new_resource_type'
    Constants::RESOURCE_TYPES.each do |type|
      expect(rendered).to have_css 'form select option', text: type
    end
    expect(rendered).to have_css 'form button.btn.btn-primary', text: 'Update'
  end
end

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'content_types/_content_type.html.erb' do
  let(:cocina_object) do
    instance_double(Cocina::Models::DRO,
                    externalIdentifier: 'druid:abc123',
                    type: Cocina::Models::ObjectType.book,
                    structural: {})
  end

  it 'renders the partial content' do
    assign(:cocina_object, cocina_object)
    render
    expect(rendered).to have_css 'form label', text: 'Old resource type'
    expect(rendered).to have_css 'select#old_resource_type'
    expect(rendered).to have_css 'form label', text: 'New content type'
    Constants::CONTENT_TYPES.each_key do |type|
      expect(rendered).to have_css 'form select option', text: type
    end
    expect(rendered).to have_css 'form select option', text: 'none', count: 3
    expect(rendered).to have_css 'select#new_content_type'
    expect(rendered).to have_css 'form label', text: 'New resource type'
    expect(rendered).to have_css 'select#new_resource_type'
    Constants::RESOURCE_TYPES.each_key do |type|
      expect(rendered).to have_css 'form select option', text: type
    end
    expect(rendered).to have_css 'form button.btn.btn-primary', text: 'Update'
  end
end

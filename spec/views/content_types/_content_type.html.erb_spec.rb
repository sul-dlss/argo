# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'content_types/_content_type' do
  before do
    @cocina = build(:dro)
    @form = ContentTypeForm.new(@cocina)

    render
  end

  it 'renders the partial content' do
    expect(rendered).to have_css 'form label', text: 'Old resource type'
    expect(rendered).to have_css 'select#content_type_new_resource_type'
    expect(rendered).to have_css 'form label', text: 'New content type'
    ContentTypeForm::CONTENT_TYPES.each_key do |type|
      expect(rendered).to have_css 'form select option', text: type
    end

    expect(rendered).to have_css 'select#content_type_viewing_direction'
    expect(rendered).to have_css 'form label', text: 'Viewing direction'

    expect(rendered).to have_css 'form select option', text: 'none', count: 4
    expect(rendered).to have_css 'select#content_type_new_content_type'
    expect(rendered).to have_css 'form label', text: 'New resource type'
    expect(rendered).to have_css 'select#content_type_new_resource_type'
    Constants::RESOURCE_TYPES.each_key do |type|
      expect(rendered).to have_css 'form select option', text: type
    end
    expect(rendered).to have_css 'form button.btn.btn-primary', text: 'Update'
  end
end

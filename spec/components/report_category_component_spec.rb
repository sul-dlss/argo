# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ReportCategoryComponent, type: :component do
  it 'renders the category fields' do
    render_inline(described_class.new(category: Report::CITATION_CATEGORY))
    expect(page).to have_content('Citation')
    expect(page).to have_field('Author', checked: false)
  end
end

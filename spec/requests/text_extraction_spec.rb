# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'TextExtractions', :js do
  let(:current_user) { create(:user) }

  before do
    sign_in current_user
  end

  it 'New page has a populate druids button and div with last search' do
    visit '/items/druid:kt881ty7544/text_extraction/new'

    expect(page).to have_css 'h3', text: 'Text Extraction'
    expect(page).to have_css 'div', text: 'Content language'

    first('button[aria-label="toggle dropdown"]').click

    find('[data-text-extraction-label="Adyghe"]').click

    expect(page).to have_css 'div', text: 'Selected language(s)'
    expect(page.all('.language-label').count).to eq 1

    find('[data-text-extraction-label="English"]').click
    expect(page.all('.language-label').count).to eq 2
  end
end

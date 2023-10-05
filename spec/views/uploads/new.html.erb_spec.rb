# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'uploads/new' do
  before do
    params[:apo_id] = 'druid:hv992yv2222'
    render
  end

  it 'has the correct title' do
    expect(rendered).to have_css('strong', text: 'Submit MODS descriptive metadata for bulk processing')
  end

  it 'has Browse, Submit and Cancel buttons' do
    expect(rendered).to have_css('input#spreadsheet_file')
    expect(rendered).to have_css('button#spreadsheet_submit')
    expect(rendered).to have_css('button#spreadsheet_cancel')
  end
end

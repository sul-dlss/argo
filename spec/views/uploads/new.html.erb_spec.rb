# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'uploads/new.html.erb', type: :view do
  before do
    @obj = double('dor_object', id: 'druid:hv992ry2431')
    render
  end

  it 'has the correct title' do
    expect(rendered).to have_css('strong', text: 'Submit MODS descriptive metadata for bulk processing')
  end

  it 'has the correct overall structure' do
    expect(rendered).to have_css('div#bulk-upload-form')
    expect(rendered).to have_css('div#spreadsheet-upload-container form div#bulk-upload-form')
    expect(rendered).to have_css('div.row.spreadsheet-row', count: 5)
    expect(rendered).to have_link('Help', href: help_apo_bulk_jobs_path('druid:hv992ry2431'))
  end

  it 'has Browse, Submit and Cancel buttons' do
    expect(rendered).to have_css('input#spreadsheet_file')
    expect(rendered).to have_css('button#spreadsheet_submit')
    expect(rendered).to have_css('button#spreadsheet_cancel')
  end
end

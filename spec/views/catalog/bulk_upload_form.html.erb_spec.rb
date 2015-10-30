require 'spec_helper'

RSpec.describe 'catalog/bulk_upload_form.html.erb', :type => :view do

  before :each do
    @obj = double('dor_object', id: 'druid:hv992ry2431')
  end

  it 'has the correct title' do
    assign(:object, @obj)
    render
    expect(rendered).to have_css('strong', :text => 'Submit MODS descriptive metadata for bulk processing')
  end

  it 'has the correct overall structure' do
    assign(:object, @obj)
    render
    expect(rendered).to have_css('div#bulk-upload-form')
    expect(rendered).to have_css('div#spreadsheet-upload-container form div#bulk-upload-form')
    expect(rendered).to have_css('div.row.spreadsheet-row', count: 5)
    expect(rendered).to have_link('Help', href: '/catalog/druid:hv992ry2431/bulk_jobs_help')
  end

  it 'has Browse, Submit and Cancel buttons' do
    assign(:object, @obj)
    render
    expect(rendered).to have_css('input#spreadsheet_file')
    expect(rendered).to have_css('button#spreadsheet_submit')
    expect(rendered).to have_css('button#spreadsheet_cancel')
  end
end

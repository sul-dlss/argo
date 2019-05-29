# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'catalog/_show_sections/file.html.erb', type: :view do
  before do
    allow(view).to receive(:can?).and_return(true)
  end

  it 'links to the file show page' do
    render partial: subject, locals: { object: 'druid:kb487gt5106', file: { 'id' => '0220_MLK_Kids_Gadson_459-25.tif' } }
    expect(rendered).to have_link('0220_MLK_Kids_Gadson_459-25.tif', href: '/items/druid:kb487gt5106/files?id=0220_MLK_Kids_Gadson_459-25.tif')
  end
end

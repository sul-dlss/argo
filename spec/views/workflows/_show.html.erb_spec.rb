# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'workflows/_show.html.erb' do
  it 'renders' do
    assign(:object, double('object', pid: 'druid:aa111bb2222'))
    assign(:workflow_id, 'accessionWF')
    render
    expect(rendered).to have_css 'table.detail'
  end
end

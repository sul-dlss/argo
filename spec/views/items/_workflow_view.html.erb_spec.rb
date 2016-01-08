require 'spec_helper'

describe 'items/_workflow_view.html.erb' do
  it 'should render' do
    assign(:object, double('object', pid: 'druid:aa111bb2222'))
    assign(:workflow_id, 'accessionWF')
    render
    expect(rendered).to have_css 'table.detail'
  end
end

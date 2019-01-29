# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'workflows/_show.html.erb' do
  let(:presenter) do
    instance_double(WorkflowPresenter,
                    pid: 'druid:aa111bb2222',
                    workflow_name: 'accessionWF',
                    processes: [])
  end

  it 'renders' do
    assign(:presenter, presenter)
    # assign(:workflow_id, 'accessionWF')
    render
    expect(rendered).to have_css 'table.detail'
  end
end

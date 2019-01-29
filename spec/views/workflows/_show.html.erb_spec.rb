# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'workflows/_show.html.erb' do
  let(:presenter) do
    instance_double(WorkflowPresenter,
                    pid: 'druid:aa111bb2222',
                    workflow_name: 'accessionWF',
                    processes: [WorkflowProcessPresenter.new(name: 'descriptive-metadata')])
  end

  it 'renders' do
    assign(:presenter, presenter)
    render
    expect(rendered).to have_css 'table.detail'
    expect(rendered).to have_text 'descriptive-metadata'
  end
end

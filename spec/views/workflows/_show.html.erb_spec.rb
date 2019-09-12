# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'workflows/_show.html.erb' do
  let(:druid) { 'druid:aa111bb2222' }
  let(:workflow_name) { 'accessionWF' }
  let(:workflow_process_presenter) do
    WorkflowProcessPresenter.new(view: view,
                                 process_status: process_status)
  end

  let(:process_status) do
    instance_double(Dor::Workflow::Response::Process,
                    name: 'descriptive-metadata',
                    status: 'waiting',
                    pid: druid,
                    workflow_name: workflow_name,
                    datetime: nil,
                    elapsed: nil,
                    attempts: nil,
                    lifecycle: nil,
                    repository: 'dor',
                    note: nil)
  end

  let(:presenter) do
    instance_double(WorkflowPresenter,
                    pid: druid,
                    workflow_name: workflow_name,
                    processes: [workflow_process_presenter])
  end

  before do
    assign(:presenter, presenter)
    allow(view).to receive(:can?).and_return(admin)
    render
  end

  context 'when authorized to make changes to workflow' do
    let(:admin) { true }

    it 'draws a table of all the workflow steps' do
      expect(rendered).to have_css 'table.detail'
      expect(rendered).to have_text 'descriptive-metadata'
      expect(rendered).to have_css 'form[action="/items/druid:aa111bb2222/workflows/accessionWF"]'
      expect(rendered).to have_button 'Set to completed'
    end
  end

  context 'when not authorized to make changes to workflow' do
    let(:admin) { false }

    it 'draws a table of all the workflow steps' do
      expect(rendered).to have_css 'table.detail'
      expect(rendered).to have_text 'descriptive-metadata'
      expect(rendered).not_to have_css 'form[action="/items/druid:aa111bb2222/workflows/accessionWF"]'
      expect(rendered).not_to have_button 'Set to completed'
    end
  end
end

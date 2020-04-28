# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WorkflowUpdateButton, type: :component do
  subject(:body) { render_inline(described_class.new(process: process)) }

  let(:process) do
    instance_double(Dor::Workflow::Response::Process,
                    status: status,
                    pid: 'druid:132',
                    workflow_name: 'accessionWF',
                    name: 'technical-metadata',
                    repository: 'dor')
  end

  context 'when the state is error' do
    let(:status) { 'error' }

    it 'renders a form with a button' do
      expect(body.css('input[name="process"]').first['value']).to eq 'technical-metadata'
      expect(body.css('button').to_html).to eq '<button name="button" type="submit" class="btn btn-secondary">Set to waiting</button>'
    end
  end

  context 'when the state is waiting' do
    let(:status) { 'waiting' }

    it 'renders a button' do
      expect(body.css('button').to_html).to eq '<button name="button" type="submit" class="btn btn-secondary">Set to completed</button>'
    end
  end

  context 'when the state is completed' do
    let(:status) { 'completed' }

    it 'renders nothing' do
      expect(body.css('*').to_html).to eq ''
    end
  end
end

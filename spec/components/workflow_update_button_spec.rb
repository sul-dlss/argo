# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WorkflowUpdateButton, type: :component do
  subject(:body) { render_inline(described_class.new(process:)) }

  let(:process) do
    instance_double(Dor::Services::Response::Process,
                    status:,
                    pid: 'druid:132',
                    workflow_name: 'accessionWF',
                    name:)
  end

  let(:name) { 'technical-metadata' }

  context 'when the state is error' do
    let(:status) { 'error' }

    it 'renders a form with a button' do
      expect(body.css('input[name="process"]').first['value']).to eq 'technical-metadata'
      expect(body.css('button').to_html).to eq \
        '<button name="button" type="submit" id="workflow-status-set-technical-metadata-waiting" class="btn btn-primary">Set to waiting</button>'
    end

    context 'when the step is sdr-ingest-received' do
      let(:name) { 'sdr-ingest-received' }

      it 'renders nothing' do
        expect(body.css('*').to_html).to eq ''
      end
    end

    context 'when the step is sdr-ingest-transfer' do
      let(:name) { 'sdr-ingest-transfer' }

      it 'renders nothing' do
        expect(body.css('*').to_html).to eq ''
      end
    end
  end

  context 'when the state is waiting' do
    let(:status) { 'waiting' }

    it 'renders a button' do
      expect(body.css('button').to_html).to eq \
        '<button name="button" type="submit" id="workflow-status-set-technical-metadata-completed" class="btn btn-primary">Set to completed</button>'
    end
  end

  context 'when the state is completed' do
    let(:status) { 'completed' }

    it 'renders nothing' do
      expect(body.css('*').to_html).to eq ''
    end
  end
end

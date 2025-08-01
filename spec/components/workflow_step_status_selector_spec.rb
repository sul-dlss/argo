# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WorkflowStepStatusSelector, type: :component do
  subject(:body) { render_inline(described_class.new(process:)) }

  let(:process) do
    instance_double(Dor::Services::Response::Process,
                    status: 'error',
                    pid: 'druid:132',
                    workflow_name: 'accessionWF',
                    name:)
  end

  context 'when a step allows all updates' do
    let(:name) { 'technical-metadata' }

    it 'has a form with all options' do
      expect(body.css('select[name="status"] > option').map(&:text)).to eq %w[Select Rerun Skip Complete]
      expect(body.css('input[name="_method"][value="put"]')).to be_present
      expect(body.css('input[name="process"]').first['value']).to eq 'technical-metadata'
    end
  end

  context 'when sdr-ingest-received' do
    let(:name) { 'sdr-ingest-received' }

    it 'has a form without skip or complete' do
      expect(body.css('select[name="status"] > option').map(&:text)).to eq %w[Select Rerun]
      expect(body.css('input[name="_method"][value="put"]')).to be_present
      expect(body.css('input[name="process"]').first['value']).to eq 'sdr-ingest-received'
    end
  end

  context 'when sdr-ingest-transfer' do
    let(:name) { 'sdr-ingest-transfer' }

    it 'has a form without skip or complete' do
      expect(body.css('select[name="status"] > option').map(&:text)).to eq %w[Select Rerun]
      expect(body.css('input[name="_method"][value="put"]')).to be_present
      expect(body.css('input[name="process"]').first['value']).to eq 'sdr-ingest-transfer'
    end
  end
end

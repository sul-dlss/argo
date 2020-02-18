# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WorkflowStepStatusSelector do
  include ActionView::Component::TestHelpers

  subject(:body) { render_inline(described_class.new(process: process)) }

  let(:process) do
    instance_double(Dor::Workflow::Response::Process,
                    status: 'error',
                    pid: 'druid:132',
                    workflow_name: 'accessionWF',
                    name: 'technical-metadata',
                    repository: 'dor')
  end

  it 'has a form' do
    expect(body.css('select[name="status"] > option').map(&:text)).to eq %w[Select Rerun Skip Complete]
    expect(body.css('input[name="_method"][value="put"]')).to be_present
    expect(body.css('input[name="process"]').first['value']).to eq 'technical-metadata'
    expect(body.css('input[name="repo"][value="dor"]')).to be_present
  end
end

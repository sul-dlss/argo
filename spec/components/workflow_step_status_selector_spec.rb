# frozen_string_literal: true

require "rails_helper"

RSpec.describe WorkflowStepStatusSelector, type: :component do
  subject(:body) { render_inline(described_class.new(process:)) }

  let(:process) do
    instance_double(Dor::Workflow::Response::Process,
      status: "error",
      pid: "druid:132",
      workflow_name: "accessionWF",
      name: "technical-metadata")
  end

  it "has a form" do
    expect(body.css('select[name="status"] > option').map(&:text)).to eq %w[Select Rerun Skip Complete]
    expect(body.css('input[name="_method"][value="put"]')).to be_present
    expect(body.css('input[name="process"]').first["value"]).to eq "technical-metadata"
  end
end

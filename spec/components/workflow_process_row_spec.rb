# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WorkflowProcessRow do
  include ActionView::Component::TestHelpers

  subject(:instance) { described_class.new(process: process_status, index: 1, item: item) }

  let(:item) { instance_double(Dor::Item) }

  describe 'render' do
    subject(:body) { render_inline(described_class.new(process: process, index: 1, item: item)) }

    let(:process) do
      instance_double(Dor::Workflow::Response::Process,
                      status: 'error',
                      pid: 'druid:132',
                      workflow_name: 'accessionWF',
                      name: 'technical-metadata',
                      repository: 'dor',
                      datetime: '2008-12-17T14:21:32Z',
                      elapsed: 1,
                      attempts: 2,
                      lifecycle: nil,
                      error_message: 'borked',
                      note: nil)
    end

    before do
      allow(controller).to receive(:can?).and_return(true)
    end

    it 'has a relative time' do
      expect(body.css('time-ago[datetime="2008-12-17T14:21:32Z"]').text).to eq '2008-12-17T14:21:32Z'
    end
  end

  describe '#elapsed' do
    subject { instance.elapsed }

    context 'for nil' do
      let(:process_status) { instance_double(Dor::Workflow::Response::Process, elapsed: nil) }

      it { is_expected.to be_nil }
    end

    context 'for empty string' do
      let(:process_status) { instance_double(Dor::Workflow::Response::Process, elapsed: '') }

      it { is_expected.to eq '0.000' }
    end

    context 'for a float' do
      let(:process_status) { instance_double(Dor::Workflow::Response::Process, elapsed: '2.25743') }

      it { is_expected.to eq '2.257' }
    end
  end

  describe '#note' do
    subject { instance.note }

    let(:process_status) { instance_double(Dor::Workflow::Response::Process, note: 'hi') }

    it { is_expected.to eq 'hi' }
  end

  describe '#error_message' do
    subject { instance.error_message }

    let(:process_status) { instance_double(Dor::Workflow::Response::Process, error_message: "it's a bad day") }

    it { is_expected.to eq "it's a bad day" }
  end
end

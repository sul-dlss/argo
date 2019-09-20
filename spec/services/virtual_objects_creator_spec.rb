# frozen_string_literal: true

require 'rails_helper'

RSpec.describe VirtualObjectsCreator do
  subject(:creator) { described_class.new(virtual_objects: virtual_objects) }

  let(:virtual_objects) do
    [
      {
        parent_id: 'druid:one123',
        child_ids: [
          'druid:two234',
          'druid:thr345'
        ]
      },
      {
        parent_id: 'druid:fou456',
        child_ids: [
          'druid:fiv567',
          'druid:six678',
          'druid:sev789'
        ]
      }
    ]
  end

  describe '.create' do
    before do
      allow(described_class).to receive(:new).and_return(creator)
    end

    # rubocop:disable RSpec/SubjectStub
    it 'creates an instance and calls `#create`' do
      allow(creator).to receive(:create)
      described_class.create(virtual_objects: virtual_objects)
      expect(creator).to have_received(:create).once
    end
    # rubocop:enable RSpec/SubjectStub
  end

  describe '.new' do
    it 'has a `virtual_objects` attribute' do
      expect(creator.virtual_objects).to eq(virtual_objects)
    end

    context 'when not passed an array' do
      let(:virtual_objects) { nil }

      it 'raises ArgumentError' do
        expect { creator.virtual_objects }.to raise_error(ArgumentError)
      end
    end

    context 'when passed an empty array' do
      let(:virtual_objects) { [] }

      it 'raises ArgumentError' do
        expect { creator.virtual_objects }.to raise_error(ArgumentError)
      end
    end
  end

  describe '#create' do
    let(:url) { 'http://dor-services.example.com/v1/background_job_results/123' }

    # rubocop:disable RSpec/SubjectStub
    before do
      allow(creator).to receive(:poll_until_complete).and_return({})
      allow(Dor::Services::Client.virtual_objects).to receive(:create)
    end
    # rubocop:enable RSpec/SubjectStub

    it 'uses dor-services-client to create a virtual object creation background job' do
      creator.create
      expect(Dor::Services::Client.virtual_objects).to have_received(:create).with(virtual_objects: virtual_objects).once
    end

    it 'calls `#poll_until_complete` to get job output' do
      allow(Dor::Services::Client.virtual_objects).to receive(:create).and_return(url)
      creator.create
      expect(creator).to have_received(:poll_until_complete).with(url: url).once
    end

    context 'when output has no errors' do
      it 'returns an empty array' do
        expect(creator.create).to eq([])
      end
    end

    context 'when output has errors' do
      # rubocop:disable RSpec/SubjectStub
      before do
        allow(creator).to receive(:poll_until_complete).and_return(
          errors: [
            { 'druid:one123' => ['druid:thr345'] },
            { 'druid:fou456' => ['druid:six678', 'druid:sev789'] }
          ]
        )
      end
      # rubocop:enable RSpec/SubjectStub

      it 'returns an array of error strings' do
        expect(creator.create).to eq(
          [
            'Problem children for druid:one123: druid:thr345',
            'Problem children for druid:fou456: druid:six678 and druid:sev789'
          ]
        )
      end
    end
  end

  describe '#poll_until_complete' do
    let(:result1) { { status: 'pending', output: {} } }
    let(:result2) { { status: 'processing', output: {} } }
    let(:result3) { { status: 'complete', output: { errors: [{ 'druid:foo' => ['druid:bar'] }] } } }

    # rubocop:disable RSpec/SubjectStub
    before do
      allow(Dor::Services::Client.background_job_results).to receive(:show).and_return(result1, result2, result3)
      allow(creator).to receive(:sleep)
    end
    # rubocop:enable RSpec/SubjectStub

    it 'loops until the job status is complete and returns an output hash' do
      output = creator.send(:poll_until_complete, url: 'not evaluated')
      expect(Dor::Services::Client.background_job_results).to have_received(:show).exactly(3).times
      expect(creator).to have_received(:sleep).twice
      expect(output).to eq(
        errors: [{ 'druid:foo' => ['druid:bar'] }]
      )
    end
  end
end

# frozen_string_literal: true

require 'rails_helper'

DRUID1 = 'druid:bb111cc2222'
DRUID2 = 'druid:cc111dd2222'

RSpec.describe BulkActionJob do
  # Setting count fields to ensure that they are reset.
  let(:bulk_action) { create(:bulk_action, druid_count_success: 100, druid_count_fail: 100, druid_count_total: 100) }

  let(:log) { instance_double(File, puts: nil, close: true) }
  let(:export_file) { instance_double(File, close: true) }

  before do
    bulk_action_job_class = Class.new(described_class)
    stub_const('TestBulkActionJob', bulk_action_job_class)

    allow_any_instance_of(TestBulkActionJob).to receive(:export_file).and_return(export_file) # rubocop:disable RSpec/AnyInstance
    allow_any_instance_of(BulkAction).to receive(:open_log_file).and_return(log) # rubocop:disable RSpec/AnyInstance
  end

  after do
    FileUtils.rm_rf(bulk_action.output_directory)
  end

  context 'when no errors' do
    before do
      bulk_action_item_class = Class.new(BulkActionJobItem) do
        def perform
          success!(message: 'Testing successful') if druid == DRUID1
          failure!(message: 'Testing failed') if druid == DRUID2
        end
      end
      stub_const('TestBulkActionJob::TestBulkActionJobItem', bulk_action_item_class)

      allow(TestBulkActionJob::TestBulkActionJobItem).to receive(:new).and_call_original
    end

    it 'performs the job' do
      TestBulkActionJob.perform_now(bulk_action.id, druids: [DRUID1, DRUID2])

      expect(TestBulkActionJob::TestBulkActionJobItem).to have_received(:new).with(druid: DRUID1, index: 0, job: instance_of(TestBulkActionJob))
      expect(TestBulkActionJob::TestBulkActionJobItem).to have_received(:new).with(druid: DRUID2, index: 1, job: instance_of(TestBulkActionJob))

      expect(log).to have_received(:puts).with(/Starting TestBulkActionJob for BulkAction #{bulk_action.id}/)
      expect(log).to have_received(:puts).with(/Finished TestBulkActionJob for BulkAction #{bulk_action.id}/)
      expect(log).to have_received(:puts).with(/Testing successful for #{DRUID1}/o)
      expect(log).to have_received(:puts).with(/Testing failed for #{DRUID2}/o)
      expect(log).to have_received(:close)
      expect(export_file).to have_received(:close)

      expect(bulk_action.reload.druid_count_total).to eq(2)
      expect(bulk_action.druid_count_success).to eq(1)
      expect(bulk_action.druid_count_fail).to eq(1)
      expect(bulk_action.status).to eq('Completed')

      expect(Dir.exist?(bulk_action.output_directory)).to be true
    end
  end

  context 'when errors' do
    before do
      bulk_action_item_class = Class.new(BulkActionJobItem) do
        def perform
          success!(message: 'Testing successful') if druid == DRUID1
          raise StandardError, 'Something bad happened' if druid == DRUID2
        end
      end
      stub_const('TestBulkActionJob::TestBulkActionJobItem', bulk_action_item_class)

      allow(TestBulkActionJob::TestBulkActionJobItem).to receive(:new).and_call_original
    end

    it 'performs the job' do
      TestBulkActionJob.perform_now(bulk_action.id, druids: [DRUID1, DRUID2])

      expect(log).to have_received(:puts).with(/Testing successful for #{DRUID1}/o)
      expect(log).to have_received(:puts).with(/Failed StandardError Something bad happened for #{DRUID2}/o)

      expect(bulk_action.reload.druid_count_total).to eq(2)
      expect(bulk_action.druid_count_success).to eq(1)
      expect(bulk_action.druid_count_fail).to eq(1)
    end
  end

  describe '.check_view_ability?' do
    let(:ability) { instance_double(Ability) }

    before do
      bulk_action_job_class = Class.new(described_class) do
        def perform_bulk_action
          return unless check_view_ability?

          super
        end
      end
      stub_const('TestCheckViewAbilityBulkActionJob', bulk_action_job_class)

      bulk_action_item_class = Class.new(BulkActionJobItem) do
        def perform; end
      end
      stub_const('TestCheckViewAbilityBulkActionJob::TestCheckViewAbilityBulkActionJobItem', bulk_action_item_class)
      allow(Ability).to receive(:new).and_return(ability)
      allow(TestCheckViewAbilityBulkActionJob::TestCheckViewAbilityBulkActionJobItem).to receive(:new).and_call_original
    end

    context 'when the user has view ability' do
      before do
        allow(ability).to receive(:can?).with(:view, Cocina::Models::DRO).and_return(true)
      end

      it 'processes the druids' do
        TestCheckViewAbilityBulkActionJob.perform_now(bulk_action.id, druids: [DRUID1, DRUID2])

        expect(TestCheckViewAbilityBulkActionJob::TestCheckViewAbilityBulkActionJobItem).to have_received(:new).twice

        expect(bulk_action.reload.druid_count_total).to eq(2)
        expect(bulk_action.druid_count_fail).to eq(0)
      end
    end

    context 'when the user does not have view ability' do
      before do
        allow(ability).to receive(:can?).with(:view, Cocina::Models::DRO).and_return(false)
      end

      it 'does not processes the druids' do
        TestCheckViewAbilityBulkActionJob.perform_now(bulk_action.id, druids: [DRUID1, DRUID2])

        expect(TestCheckViewAbilityBulkActionJob::TestCheckViewAbilityBulkActionJobItem).not_to have_received(:new)

        expect(log).to have_received(:puts).with(/Not authorized to view all content/)

        expect(bulk_action.reload.druid_count_total).to eq(2)
        expect(bulk_action.druid_count_fail).to eq(2)
      end
    end
  end
end

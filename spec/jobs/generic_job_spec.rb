require 'spec_helper'

class GenericTestJob < GenericJob
  def perform(_bulk_action_id, _params)
    bulk_action.increment(:druid_count_success).save!
    bulk_action.increment(:druid_count_fail).save!
  end
end

describe GenericJob do
  let(:bulk_action_no_process_callback) do
    bulk_action = build(
      :bulk_action,
      action_type: 'GenericJob',
      druid_count_total: 2
    )
    expect(bulk_action).to receive(:process_bulk_action_type)
    bulk_action.save!
    bulk_action
  end

  before do
    allow(subject).to receive(:bulk_action).and_return(bulk_action_no_process_callback)
  end

  describe '#with_bulk_action_log' do
    it 'should open a log buffer in append mode, and pass it to the block' do
      buffer = StringIO.new
      expect(File).to receive(:open).with(bulk_action_no_process_callback.log_name, 'a').and_yield(buffer)

      subject.with_bulk_action_log do |my_log_buf|
        expect(my_log_buf).to eq buffer
      end
    end
  end

  describe 'before_perform' do
    it 'resets the druid counts before the job gets (re-)run' do
      lock_obj = double('lock')
      allow(BulkAction).to receive(:lock).and_return(lock_obj)
      allow(lock_obj).to receive(:find).with(bulk_action_no_process_callback.id).and_return(bulk_action_no_process_callback)

      GenericTestJob.perform_now(bulk_action_no_process_callback.id, {})
      expect(bulk_action_no_process_callback.druid_count_success).to eq 1
      expect(bulk_action_no_process_callback.druid_count_fail).to eq 1
      expect(bulk_action_no_process_callback.druid_count_total).to eq 2

      GenericTestJob.perform_now(bulk_action_no_process_callback.id, {})
      expect(bulk_action_no_process_callback.druid_count_success).to eq 1
      expect(bulk_action_no_process_callback.druid_count_fail).to eq 1
      expect(bulk_action_no_process_callback.druid_count_total).to eq 2
    end
  end
end

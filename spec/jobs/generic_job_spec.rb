require 'spec_helper'

describe GenericJob do
  let(:bulk_action_no_process_callback) do
    bulk_action = build(
      :bulk_action,
      action_type: 'GenericJob'
    )
    expect(bulk_action).to receive(:process_bulk_action_type)
    bulk_action.save
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
end

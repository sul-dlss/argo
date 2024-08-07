# frozen_string_literal: true

require 'rails_helper'

class GenericTestJob < GenericJob
  def perform(_bulk_action_id, _params)
    bulk_action.increment(:druid_count_success)
    bulk_action.increment(:druid_count_fail)
    bulk_action.increment(:druid_count_total)
    bulk_action.save
  end
end

RSpec.describe GenericJob do
  let(:bulk_action) { create(:bulk_action) }

  before do
    allow(subject).to receive(:bulk_action).and_return(bulk_action)
  end

  describe '#with_bulk_action_log' do
    it 'opens a log buffer in append mode, and pass it to the block' do
      buffer = StringIO.new
      expect(File).to receive(:open).with(bulk_action.log_name, 'a').and_yield(buffer)

      subject.with_bulk_action_log do |my_log_buf|
        expect(my_log_buf).to eq buffer
      end
    end
  end

  describe 'before_perform' do
    it 'resets the druid counts before the job gets (re-)run' do
      allow(BulkAction).to receive(:find).with(bulk_action.id).and_return(bulk_action)

      GenericTestJob.perform_now(bulk_action.id, {})
      expect(bulk_action.druid_count_success).to eq 1
      expect(bulk_action.druid_count_fail).to eq 1
      expect(bulk_action.druid_count_total).to eq 1

      GenericTestJob.perform_now(bulk_action.id, {})
      expect(bulk_action.druid_count_success).to eq 1
      expect(bulk_action.druid_count_fail).to eq 1
      expect(bulk_action.druid_count_total).to eq 1
    end
  end

  describe '#open_new_version' do
    let(:current_user) do
      instance_double(User,
                      admin?: true)
    end
    let(:druid) { 'druid:123abc' }
    let(:version) { 1 }
    let(:workflow) { double('workflow') }
    let(:log) { double('log') }
    let(:webauth) { OpenStruct.new('privgroup' => 'dorstuff', 'login' => 'someuser') }
    let(:client) { instance_double(Dor::Services::Client::Object, version: version_client) }
    let(:cocina_object) { instance_double(Cocina::Models::DROWithMetadata, externalIdentifier: druid, version:) }
    let(:new_cocina_object) { instance_double(Cocina::Models::DROWithMetadata) }

    context 'when openable' do
      before do
        allow(VersionService).to receive_messages(openable?: true, open: new_cocina_object)
      end

      it 'opens a new version' do
        expect(subject.send(:open_new_version, cocina_object, 'Set new governing APO')).to eq(new_cocina_object)

        expect(VersionService).to have_received(:openable?).with(druid:)
        expect(VersionService).to have_received(:open).with(
          druid:,
          description: 'Set new governing APO',
          opening_user_name: subject.bulk_action.user.to_s
        )
      end
    end

    context 'when not openable' do
      before do
        allow(VersionService).to receive(:openable?).and_return(false)
        allow(VersionService).to receive(:open)
      end

      it 'does not open a new version if rejected by the workflow status' do
        expect { subject.send(:open_new_version, cocina_object, 'Message') }.to raise_error(/Unable to open new version/)

        expect(VersionService).to have_received(:openable?).with(druid:)
        expect(VersionService).not_to have_received(:open)
      end
    end
  end
end

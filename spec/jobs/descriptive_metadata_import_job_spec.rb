# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DescriptiveMetadataImportJob do
  let(:bulk_action) { create(:bulk_action, action_type: described_class.to_s) }
  let(:item1) { build(:dro_with_metadata, id: 'druid:bc123df4567') }
  let(:item2) { build(:dro_with_metadata, id: 'druid:df321cb7654', version: 2) }
  let(:object_client1) { instance_double(Dor::Services::Client::Object, find: item1) }
  let(:object_client2) { instance_double(Dor::Services::Client::Object, find: item2) }
  let(:filename) { 'test.csv' }
  let(:log_buffer) { StringIO.new }
  let(:csv_file) do
    [
      'druid,source_id,title1:value,purl',
      [item1.externalIdentifier, item1.identification.sourceId, 'new title 1', "https://purl.stanford.edu/#{item1.externalIdentifier.delete_prefix('druid:')}"].join(','),
      [item2.externalIdentifier, item2.identification.sourceId, 'new title 2', "https://purl.stanford.edu/#{item2.externalIdentifier.delete_prefix('druid:')}"].join(',')
    ].join("\n")
  end

  before do
    allow(BulkJobLog).to receive(:open).and_yield(log_buffer)
    allow(subject).to receive(:bulk_action).and_return(bulk_action)
    allow(Repository).to receive(:find).with(item1.externalIdentifier).and_return(item1)
    allow(Repository).to receive(:find).with(item2.externalIdentifier).and_return(item2)
    allow(Dor::Services::Client).to receive(:object).with(item1.externalIdentifier).and_return(object_client1)
    allow(Dor::Services::Client).to receive(:object).with(item2.externalIdentifier).and_return(object_client2)
    allow(VersionService).to receive(:open?).and_return(true)
  end

  describe '#perform' do
    before do
      allow(Repository).to receive(:store)
      allow(VersionService).to receive(:open)
      allow(VersionService).to receive(:close)
    end

    context 'when authorized' do
      before do
        allow(Ability).to receive(:new).and_return(ability)
        subject.perform(bulk_action.id, { csv_file:, csv_filename: filename })
      end

      let(:ability) { instance_double(Ability, can?: true) }

      let(:expected1) do
        item1.new(description: item1.description.new(title: [{ value: 'new title 1' }], purl: "https://purl.stanford.edu/#{item1.externalIdentifier.delete_prefix('druid:')}"))
      end

      let(:expected2) do
        item2.new(description: item2.description.new(title: [{ value: 'new title 2' }], purl: "https://purl.stanford.edu/#{item2.externalIdentifier.delete_prefix('druid:')}"))
      end

      it 'updates the descriptive metadata for each item and closes each item' do
        expect(bulk_action.druid_count_total).to eq(2)
        expect(bulk_action.druid_count_fail).to eq(0)
        expect(bulk_action.druid_count_success).to eq(2)
        expect(Repository).to have_received(:store).with(expected1)
        expect(Repository).to have_received(:store).with(expected2)
        expect(VersionService).to have_received(:open?).twice
        expect(VersionService).to have_received(:close).once
      end
    end

    context 'when not authorized' do
      before do
        subject.perform(bulk_action.id, { csv_file:, csv_filename: filename })
      end

      it 'does not update or close items' do
        expect(bulk_action.druid_count_total).to eq(2)
        expect(Repository).not_to have_received(:store)
        expect(VersionService).not_to have_received(:close)
      end
    end

    context 'when validation fails' do
      let(:csv_file) do
        [
          'druid,source_id,title1.structuredValue1.value,purl',
          [item1.externalIdentifier, item1.identification.sourceId, 'new title 1', "https://purl.stanford.edu/x#{item1.externalIdentifier.delete_prefix('druid:')}"].join(',')
        ].join("\n")
      end
      let(:ability) { instance_double(Ability, can?: true) }

      before do
        allow(Ability).to receive(:new).and_return(ability)
        allow(Honeybadger).to receive(:notify)
        subject.perform(bulk_action.id, { csv_file:, csv_filename: filename })
      end

      it 'updates the error count without opening, alerting honeybadger, updating or closing' do
        expect(bulk_action.druid_count_total).to eq 1
        expect(bulk_action.druid_count_fail).to eq 1
        expect(bulk_action.druid_count_success).to eq 0
        expect(VersionService).not_to have_received(:open)
        expect(Repository).not_to have_received(:store)
        expect(Honeybadger).not_to have_received(:notify)
        expect(VersionService).not_to have_received(:close)
      end
    end

    context 'when missing druid column' do
      let(:csv_file) do
        [
          'source_id,title1:value,purl',
          [item1.identification.sourceId, 'new title 1', "https://purl.stanford.edu/#{item1.externalIdentifier.delete_prefix('druid:')}"].join(',')
        ].join("\n")
      end

      let(:ability) { instance_double(Ability, can?: true) }

      before do
        allow(Ability).to receive(:new).and_return(ability)
        allow(Honeybadger).to receive(:notify)
        subject.perform(bulk_action.id, { csv_file:, csv_filename: filename })
      end

      it 'logs the error without alerting honeybadger' do
        expect(bulk_action.druid_count_total).to eq 1
        expect(bulk_action.druid_count_fail).to eq 1
        expect(bulk_action.druid_count_success).to eq 0
        expect(Repository).not_to have_received(:store)
        expect(Honeybadger).not_to have_received(:notify)
        expect(log_buffer.string).to include 'Column "druid" not found'
      end
    end

    context 'when unchanged' do
      before do
        allow(Ability).to receive(:new).and_return(ability)
        subject.perform(bulk_action.id, { csv_file:, csv_filename: filename })
      end

      let(:ability) { instance_double(Ability, can?: true) }

      let(:csv_file) do
        [
          'druid,source_id,title1:value,purl',
          [item1.externalIdentifier, item1.identification.sourceId, 'factory DRO title', "https://purl.stanford.edu/#{item1.externalIdentifier.delete_prefix('druid:')}"].join(',')
        ].join("\n")
      end

      it 'does not update the descriptive metadata or close the items' do
        expect(bulk_action.druid_count_total).to eq 1
        expect(bulk_action.druid_count_fail).to eq 1
        expect(bulk_action.druid_count_success).to eq 0
        expect(Repository).not_to have_received(:store)
        expect(VersionService).not_to have_received(:close)
      end
    end

    context 'when not open' do
      before do
        allow(Ability).to receive(:new).and_return(ability)
        allow(VersionService).to receive_messages(open?: false, openable?: true, open: item1.new(version: 2))
        subject.perform(bulk_action.id, { csv_file:, csv_filename: filename })
      end

      let(:csv_file) do
        [
          'druid,source_id,title1:value,purl',
          [item1.externalIdentifier, item1.identification.sourceId, 'new title 1', "https://purl.stanford.edu/#{item1.externalIdentifier.delete_prefix('druid:')}"].join(',')
        ].join("\n")
      end

      let(:ability) { instance_double(Ability, can?: true) }

      let(:expected1) do
        item1.new(version: 2, description: item1.description.new(title: [{ value: 'new title 1' }], purl: "https://purl.stanford.edu/#{item1.externalIdentifier.delete_prefix('druid:')}"))
      end

      it 'opens the item, updates the descriptive metadata and then closes the item' do
        expect(bulk_action.druid_count_total).to eq 1
        expect(Repository).to have_received(:store).with(expected1)
        expect(VersionService).to have_received(:open?)
        expect(VersionService).to have_received(:open).with(druid: item1.externalIdentifier, opening_user_name: bulk_action.user.to_s,
                                                            description: 'Descriptive metadata upload')
        expect(VersionService).to have_received(:close).once
        expect(log_buffer.string).to include "CSV filename: #{filename}"
      end
    end
  end
end

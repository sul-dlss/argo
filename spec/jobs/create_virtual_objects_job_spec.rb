# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CreateVirtualObjectsJob do
  subject(:job) { described_class.new }

  let(:bulk_action) { create(:bulk_action) }
  let(:csv_string) { "parent1,one,two\nparent2,three,four,five" }
  let(:errors) { [] }
  let(:log) { instance_double(File, puts: nil, close: true) }

  before do
    allow(BulkAction).to receive(:find).and_return(bulk_action)
    allow(ProblematicDruidFinder).to receive(:find).and_return(problematic_druids)
    allow(VirtualObjectsCreator).to receive(:create).and_return(errors)
    allow_any_instance_of(BulkAction).to receive(:open_log_file).and_return(log) # rubocop:disable RSpec/AnyInstance

    job.perform(bulk_action.id, csv_file: csv_string)
  end

  describe '#perform' do
    context 'with all problematic druids' do
      let(:problematic_druids) { [['druid:parent2'], ['druid:parent1']] }

      it 'short-circuits invoking the virtual objects creator service' do
        expect(VirtualObjectsCreator).not_to have_received(:create)
      end

      it 'logs informative messages' do
        expect(log).to have_received(:puts).with(/Starting CreateVirtualObjectsJob for BulkAction/).once
        expect(log).to have_received(:puts)
          .with(/Could not create virtual objects because user lacks ability to manage the following virtual object druids: druid:parent1/)
          .once
        expect(log).to have_received(:puts).with(/Could not create virtual objects because the following virtual object druids were not found: druid:parent2/).once
        expect(log).to have_received(:puts).with(/No virtual objects could be created. See other log entries for more detail/).once
        expect(log).to have_received(:puts).with(/Finished CreateVirtualObjectsJob for BulkAction/).once
      end

      it 'has the expected total/success/fail counts' do
        expect(bulk_action.druid_count_total).to eq(2)
        expect(bulk_action.druid_count_success).to eq(0)
        expect(bulk_action.druid_count_fail).to eq(2)
      end
    end

    context 'with some problematic druids' do
      let(:problematic_druids) { [[], ['druid:parent1']] }

      it 'invokes the virtual objects creator service with an array of length 1' do
        expect(VirtualObjectsCreator).to have_received(:create).with(
          virtual_objects: [
            { virtual_object_id: 'druid:parent2', constituent_ids: %w[druid:three druid:four druid:five] }
          ]
        ).once
      end

      it 'logs informative messages' do
        expect(log).to have_received(:puts).with(/Starting CreateVirtualObjectsJob for BulkAction/).once
        expect(log).to have_received(:puts)
          .with(/Could not create virtual objects because user lacks ability to manage the following virtual object druids: druid:parent1/)
          .once
        expect(log).to have_received(:puts).with(/Successfully created virtual objects: druid:parent2/)
        expect(log).to have_received(:puts).with(/Finished CreateVirtualObjectsJob for BulkAction/).once
      end

      it 'has the expected total/success/fail counts' do
        expect(bulk_action.druid_count_total).to eq(2)
        expect(bulk_action.druid_count_success).to eq(1)
        expect(bulk_action.druid_count_fail).to eq(1)
      end
    end

    context 'without problematic druids' do
      let(:problematic_druids) { [[], []] }

      it 'invokes the virtual objects creator service with an array of length 2' do
        expect(VirtualObjectsCreator).to have_received(:create).with(
          virtual_objects: [
            { virtual_object_id: 'druid:parent1', constituent_ids: %w[druid:one druid:two] },
            { virtual_object_id: 'druid:parent2', constituent_ids: %w[druid:three druid:four druid:five] }
          ]
        ).once
      end

      it 'logs informative messages' do
        expect(log).to have_received(:puts).with(/Starting CreateVirtualObjectsJob for BulkAction/).once
        expect(log).to have_received(:puts).with(/Successfully created virtual objects: druid:parent1 and druid:parent2/)
        expect(log).to have_received(:puts).with(/Finished CreateVirtualObjectsJob for BulkAction/).once
      end

      it 'has the expected total/success/fail counts' do
        expect(bulk_action.druid_count_total).to eq(2)
        expect(bulk_action.druid_count_success).to eq(2)
        expect(bulk_action.druid_count_fail).to eq(0)
      end

      context 'when creator service returns errors' do
        let(:errors) { ['parent1 is citation-only'] }

        it 'logs informative messages' do
          expect(log).to have_received(:puts).with(/Starting CreateVirtualObjectsJob for BulkAction/).once
          expect(log).to have_received(:puts).with(/Creating some or all virtual objects failed because some objects are not combinable: parent1 is citation-only/)
          expect(log).to have_received(:puts).with(/Finished CreateVirtualObjectsJob for BulkAction/).once
        end

        it 'has the expected total/success/fail counts' do
          expect(bulk_action.druid_count_total).to eq(2)
          expect(bulk_action.druid_count_success).to eq(1)
          expect(bulk_action.druid_count_fail).to eq(1)
        end
      end
    end
  end
end

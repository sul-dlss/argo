# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SetLicenseAndRightsStatementsJob do
  let(:bulk_action) { create(:bulk_action) }
  let(:groups) { ['workgroup:sdr:administrator-role'] }

  let(:druids) { ['druid:123', 'druid:456'] }
  let(:user) { instance_double(User, to_s: 'jcoyne85') }
  let(:logger) { instance_double(File, puts: nil) }

  describe '#perform' do
    let(:allows_modification) { true }
    let(:params) do
      {
        copyright_statement_option: '1',
        copyright_statement:,
        druids:,
        groups:
      }.with_indifferent_access
    end
    let(:cocina_object) { build(:dro_with_metadata) }
    let(:copyright_statement) { 'the new hotness' }
    let(:state_service) { instance_double(StateService, allows_modification?: allows_modification) }
    let(:wf_status) { instance_double(DorObjectWorkflowStatus, can_open_version?: true) }

    before do
      allow(BulkJobLog).to receive(:open).and_yield(logger)
      allow(Repository).to receive(:find).and_return(cocina_object)
      allow(DorObjectWorkflowStatus).to receive(:new).and_return(wf_status)
      allow(CollectionChangeSetPersister).to receive(:update)
      allow(ItemChangeSetPersister).to receive(:update)
      allow(VersionService).to receive(:open).and_return(cocina_object)
      allow(StateService).to receive(:new).and_return(state_service)
    end

    context 'when happy path' do
      let(:groups) { ['workgroup:sdr:administrator-role'] }

      before do
        described_class.perform_now(bulk_action.id, params)
      end

      context 'with an item that is already opened' do
        it 'updates via item change set persister' do
          expect(VersionService).not_to have_received(:open)
          expect(ItemChangeSetPersister).to have_received(:update).twice
        end
      end

      context 'with an item that needs to be opened first' do
        let(:allows_modification) { false }

        it 'updates via item change set persister' do
          expect(VersionService).to have_received(:open).twice
          expect(ItemChangeSetPersister).to have_received(:update).twice
        end
      end

      context 'with an item and the none license URI' do
        let(:instance_args) { { license: '' } }
        let(:params) do
          {
            license_option: '1',
            license: '',
            druids:,
            groups:
          }.with_indifferent_access
        end

        it 'updates via item change set persister' do
          expect(VersionService).not_to have_received(:open)
          expect(ItemChangeSetPersister).to have_received(:update).twice
        end
      end

      context 'with a collection' do
        let(:cocina_object) { build(:collection_with_metadata) }

        it 'updates via collection change set persister' do
          expect(VersionService).not_to have_received(:open)
          expect(CollectionChangeSetPersister).to have_received(:update).twice
        end
      end
    end

    context 'with an unsupported object type' do
      let(:cocina_object) { build(:admin_policy) }

      before do
        described_class.perform_now(bulk_action.id, params)
        bulk_action.reload
      end

      it 'logs errors' do
        expect(logger).to have_received(:puts).with(%r{Not an item or collection \(https://cocina.sul.stanford.edu/models/admin_policy\)}).twice
        expect(bulk_action.druid_count_total).to eq(druids.length)
        expect(bulk_action.druid_count_fail).to eq(druids.length)
      end
    end

    context 'when no changes' do
      let(:params) do
        {
          copyright_statement_option: '',
          druids:,
          groups:
        }.with_indifferent_access
      end

      before do
        described_class.perform_now(bulk_action.id, params)
        bulk_action.reload
      end

      it 'logs errors' do
        expect(VersionService).not_to have_received(:open)
        expect(CollectionChangeSetPersister).not_to have_received(:update)
        expect(logger).to have_received(:puts).with(/No changes made/).twice
        expect(bulk_action.druid_count_total).to eq(druids.length)
        expect(bulk_action.druid_count_success).to eq(druids.length)
      end
    end

    context 'when user is unauthorized' do
      let(:groups) { [] }

      let(:params) do
        {
          copyright_statement_option: '1',
          copyright_statement: 'test',
          druids:,
          groups:
        }.with_indifferent_access
      end

      before do
        described_class.perform_now(bulk_action.id, params)
        bulk_action.reload
      end

      it 'logs errors' do
        expect(logger).to have_received(:puts).with(/Not authorized/).twice
        expect(bulk_action.druid_count_total).to eq(druids.length)
        expect(bulk_action.druid_count_fail).to eq(druids.length)
      end
    end

    context 'when item cannot be opened' do
      let(:allows_modification) { false }
      let(:wf_status) { instance_double(DorObjectWorkflowStatus, can_open_version?: false) }

      before do
        described_class.perform_now(bulk_action.id, params)
        bulk_action.reload
      end

      it 'logs errors' do
        expect(logger).to have_received(:puts).with(/Unable to open new version/).twice
        expect(bulk_action.druid_count_total).to eq(druids.length)
        expect(bulk_action.druid_count_fail).to eq(druids.length)
      end
    end
  end
end

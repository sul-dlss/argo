# frozen_string_literal: true

require 'rails_helper'

RSpec.describe LicenseAndRightsStatementsSetter do
  let(:ability) { instance_double(Ability, can?: authorized, current_user: user) }
  let(:authorized) { true }
  let(:druid) { 'druid:bc123df4567' }
  let(:user) { build(:user) }

  describe '.set' do
    let(:instance) { instance_double(described_class, set: nil) }

    before do
      allow(described_class).to receive(:new).and_return(instance)
      described_class.set(ability: ability, druid: druid)
    end

    it 'invokes #set on a new instance' do
      expect(instance).to have_received(:set).once
    end
  end

  describe '#set' do
    let(:allows_modification) { true }
    let(:instance_args) { { copyright: copyright_statement } }
    let(:item) { build(:item) }
    let(:copyright_statement) { 'the new hotness' }
    let(:fake_state_service) { instance_double(StateService, allows_modification?: allows_modification) }
    let(:instance) do
      described_class.new(
        ability: ability,
        druid: druid,
        **instance_args
      )
    end
    let(:openable) { true }

    before do
      allow(Repository).to receive(:find).and_return(item)
      allow(item).to receive(:save)
      # allow_any_instance_of(Dor::Services::Client::Object).to receive(:find).and_raise 'hi' #return(cocina_object)
      allow_any_instance_of(DorObjectWorkflowStatus).to receive(:can_open_version?).and_return(openable)
      allow(instance).to receive(:state_service).and_return(fake_state_service)
      allow(CollectionPersister).to receive(:update)
      allow(ItemPersister).to receive(:update)
      allow(VersionService).to receive(:open)
    end

    context 'when happy path' do
      before do
        instance.set
      end

      context 'with an item that is already opened' do
        it 'updates' do
          expect(VersionService).not_to have_received(:open)
          expect(item).to have_received(:save)
        end
      end

      context 'with an item that needs to be opened first' do
        let(:allows_modification) { false }

        it 'updates' do
          expect(VersionService).to have_received(:open).once
          expect(item).to have_received(:save)
        end
      end

      context 'with an item and the none license URI' do
        let(:instance_args) { { license: '' } }

        it 'updates' do
          expect(VersionService).not_to have_received(:open)
          expect(item).to have_received(:save)
        end
      end

      context 'with a collection' do
        let(:item) { build(:collection) }

        it 'updates via collection' do
          expect(VersionService).not_to have_received(:open)
          expect(item).to have_received(:save)
        end
      end
    end

    context 'with an unsupported object type' do
      let(:item) { build(:admin_policy) }

      it 'raises' do
        expect { instance.set }.to raise_error(RuntimeError, /is not an item or collection/)
      end
    end

    context 'when no changes' do
      let(:instance_args) { {} }

      it 'returns nil' do
        expect(VersionService).not_to have_received(:open)
        expect(CollectionPersister).not_to have_received(:update)
        expect(instance.set).to be_nil
      end
    end

    context 'when user is unauthorized' do
      let(:authorized) { false }

      it 'raises' do
        expect { instance.set }.to raise_error(RuntimeError, /cannot be changed by/)
      end
    end

    context 'when item cannot be opened' do
      let(:allows_modification) { false }
      let(:openable) { false }

      it 'raises' do
        expect { instance.set }.to raise_error(RuntimeError, /unable to open new version for/)
      end
    end
  end
end

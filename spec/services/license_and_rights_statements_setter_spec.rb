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
    let(:cocina_object) do
      Cocina::Models::DRO.new(
        externalIdentifier: 'druid:bc123df4568',
        label: 'test',
        type: Cocina::Models::ObjectType.object,
        version: 1,
        description: {
          title: [{ value: 'test' }],
          purl: 'https://purl.stanford.edu/bc123df4567'
        },
        access: {},
        administrative: { hasAdminPolicy: 'druid:bc123df4569' }
      )
    end
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
      allow_any_instance_of(Dor::Services::Client::Object).to receive(:find).and_return(cocina_object)
      allow_any_instance_of(DorObjectWorkflowStatus).to receive(:can_open_version?).and_return(openable)
      allow(instance).to receive(:state_service).and_return(fake_state_service)
      allow(CollectionChangeSetPersister).to receive(:update)
      allow(ItemChangeSetPersister).to receive(:update)
      allow(VersionService).to receive(:open)
    end

    context 'when happy path' do
      before do
        instance.set
      end

      context 'with an item that is already opened' do
        it 'updates via item change set persister' do
          expect(VersionService).not_to have_received(:open)
          expect(ItemChangeSetPersister).to have_received(:update).once
        end
      end

      context 'with an item that needs to be opened first' do
        let(:allows_modification) { false }

        it 'updates via item change set persister' do
          expect(VersionService).to have_received(:open).once
          expect(ItemChangeSetPersister).to have_received(:update).once
        end
      end

      context 'with an item and the none license URI' do
        let(:instance_args) { { license: '' } }

        it 'updates via item change set persister' do
          expect(VersionService).not_to have_received(:open)
          expect(ItemChangeSetPersister).to have_received(:update).once
        end
      end

      context 'with a collection' do
        let(:cocina_object) do
          Cocina::Models::Collection.new(
            externalIdentifier: 'druid:bc123df4568',
            label: 'test',
            type: Cocina::Models::ObjectType.collection,
            description: {
              title: [{ value: 'test' }],
              purl: 'https://purl.stanford.edu/bc123df4567'
            },
            version: 1,
            access: {}
          )
        end

        it 'updates via collection change set persister' do
          expect(VersionService).not_to have_received(:open)
          expect(CollectionChangeSetPersister).to have_received(:update).once
        end
      end
    end

    context 'with an unsupported object type' do
      let(:cocina_object) do
        Cocina::Models::AdminPolicy.new(
          externalIdentifier: 'druid:bc123df4570',
          label: 'test',
          type: Cocina::Models::ObjectType.admin_policy,
          version: 1,
          administrative: {
            hasAdminPolicy: 'druid:bc123df4570',
            hasAgreement: 'druid:hp308wm0436',
            accessTemplate: { view: 'world', download: 'world' }
          }
        )
      end

      it 'raises' do
        expect { instance.set }.to raise_error(RuntimeError, /is not an item or collection/)
      end
    end

    context 'when no changes' do
      let(:instance_args) { {} }

      it 'returns nil' do
        expect(VersionService).not_to have_received(:open)
        expect(CollectionChangeSetPersister).not_to have_received(:update)
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

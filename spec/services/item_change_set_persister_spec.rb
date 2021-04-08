# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ItemChangeSetPersister do
  describe '.update' do
    let(:change_set) { instance_double(ItemChangeSet) }
    let(:instance) { instance_double(described_class, update: nil) }
    let(:model) { instance_double(Cocina::Models::DRO) }

    before do
      allow(described_class).to receive(:new).and_return(instance)
      described_class.update(model, change_set)
    end

    it 'calls #update on a new instance' do
      expect(instance).to have_received(:update).once
    end
  end

  describe '#update' do
    let(:copyright_statement_before) { 'My First Copyright Statement' }
    let(:fake_client) { instance_double(Dor::Services::Client::Object, update: nil) }
    let(:instance) do
      described_class.new(model, change_set)
    end
    let(:license_before) { 'http://opendatacommons.org/licenses/pddl/1.0/' }
    let(:model) do
      Cocina::Models::DRO.new(
        externalIdentifier: 'druid:bc123df4568',
        label: 'test',
        type: Cocina::Models::Vocab.object,
        version: 1,
        access: {
          copyright: copyright_statement_before,
          license: license_before,
          useAndReproductionStatement: use_statement_before
        },
        administrative: { hasAdminPolicy: 'druid:bc123df4569' }
      )
    end
    let(:use_statement_before) { 'My First Use Statement' }

    before do
      allow(instance).to receive(:object_client).and_return(fake_client)
      instance.update
    end

    context 'when change set has changed copyright statement' do
      let(:change_set) do
        instance_double(
          ItemChangeSet,
          copyright_statement: new_copyright_statement,
          copyright_statement_changed?: true,
          license_changed?: false,
          use_statement_changed?: false,
          collection_ids_changed?: false,
          source_id_changed?: false,
          catkey_changed?: false,
          admin_policy_id_changed?: false
        )
      end
      let(:new_copyright_statement) { 'A Changed Copyright Statement' }

      it 'invokes object client with item/DRO that has new copyright statement' do
        expect(fake_client).to have_received(:update).with(
          params: a_cocina_object_with_access(
            copyright: new_copyright_statement,
            license: license_before,
            useAndReproductionStatement: use_statement_before
          )
        )
      end
    end

    context 'when change set has changed license' do
      let(:change_set) do
        instance_double(
          ItemChangeSet,
          copyright_statement_changed?: false,
          license: new_license,
          license_changed?: true,
          use_statement_changed?: false,
          collection_ids_changed?: false,
          source_id_changed?: false,
          catkey_changed?: false,
          admin_policy_id_changed?: false
        )
      end
      let(:new_license) { 'https://creativecommons.org/licenses/by-nc-nd/3.0/' }

      it 'invokes object client with item/DRO that has new license' do
        expect(fake_client).to have_received(:update).with(
          params: a_cocina_object_with_access(
            copyright: copyright_statement_before,
            license: new_license,
            useAndReproductionStatement: use_statement_before
          )
        )
      end
    end

    context 'when change set has changed use statement' do
      let(:change_set) do
        instance_double(
          ItemChangeSet,
          copyright_statement_changed?: false,
          license_changed?: false,
          use_statement: new_use_statement,
          use_statement_changed?: true,
          collection_ids_changed?: false,
          source_id_changed?: false,
          catkey_changed?: false,
          admin_policy_id_changed?: false
        )
      end
      let(:new_use_statement) { 'A Changed Use Statement' }

      it 'invokes object client with item/DRO that has new use statement' do
        expect(fake_client).to have_received(:update).with(
          params: a_cocina_object_with_access(
            copyright: copyright_statement_before,
            license: license_before,
            useAndReproductionStatement: new_use_statement
          )
        )
      end
    end

    context 'when change set has one changed property and another nil' do
      let(:change_set) do
        instance_double(
          ItemChangeSet,
          copyright_statement_changed?: false,
          license_changed?: false,
          use_statement: new_use_statement,
          use_statement_changed?: true,
          collection_ids_changed?: false,
          source_id_changed?: false,
          catkey_changed?: false,
          admin_policy_id_changed?: false
        )
      end
      let(:model) do
        Cocina::Models::DRO.new(
          externalIdentifier: 'druid:bc123df4568',
          label: 'test',
          type: Cocina::Models::Vocab.object,
          version: 1,
          access: {
            # NOTE: missing copyright here
            license: license_before,
            useAndReproductionStatement: use_statement_before
          },
          administrative: { hasAdminPolicy: 'druid:bc123df4569' }
        )
      end
      let(:new_use_statement) { 'A Changed Use Statement' }

      it 'invokes object client with item/DRO that has new use statement' do
        expect(fake_client).to have_received(:update).with(
          params: a_cocina_object_with_access(
            license: license_before,
            useAndReproductionStatement: new_use_statement
          )
        )
      end
    end

    context 'when change set has no changes' do
      let(:change_set) do
        instance_double(
          ItemChangeSet,
          copyright_statement_changed?: false,
          license_changed?: false,
          use_statement_changed?: false,
          collection_ids_changed?: false,
          source_id_changed?: false,
          catkey_changed?: false,
          admin_policy_id_changed?: false
        )
      end

      it 'invokes object client with item/DRO as before' do
        expect(fake_client).to have_received(:update).with(
          params: a_cocina_object_with_access(
            copyright: copyright_statement_before,
            license: license_before,
            useAndReproductionStatement: use_statement_before
          )
        )
      end
    end
  end
end

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CollectionChangeSetPersister do
  describe '.update' do
    let(:change_set) { instance_double(CollectionChangeSet) }
    let(:instance) { instance_double(described_class, update: nil) }
    let(:model) { instance_double(Cocina::Models::Collection) }

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
    let(:change_set) { CollectionChangeSet.new(model) }
    let(:license_before) { 'https://opendatacommons.org/licenses/pddl/1-0/' }
    let(:model) do
      Cocina::Models::Collection.new(
        externalIdentifier: 'druid:bc123df4568',
        label: 'test',
        type: Cocina::Models::ObjectType.collection,
        version: 1,
        description: {
          title: [{ value: 'test' }],
          purl: 'https://purl.stanford.edu/bc123df4568'
        },
        identification: {},
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
    end

    context 'when change set has changed copyright statement' do
      before do
        change_set.validate(copyright: new_copyright_statement)
        instance.update
      end

      let(:new_copyright_statement) { 'A Changed Copyright Statement' }

      it 'invokes object client with collection that has new copyright statement' do
        expect(fake_client).to have_received(:update).with(
          params: cocina_object_with(
            access: {
              copyright: new_copyright_statement,
              license: license_before,
              useAndReproductionStatement: use_statement_before
            }
          )
        )
      end
    end

    context 'when change set has changed license' do
      before do
        change_set.validate(license: new_license)
        instance.update
      end

      let(:new_license) { 'https://creativecommons.org/licenses/by-nc-nd/3.0/legalcode' }

      it 'invokes object client with collection that has new license' do
        expect(fake_client).to have_received(:update).with(
          params: cocina_object_with(
            access: {
              copyright: copyright_statement_before,
              license: new_license,
              useAndReproductionStatement: use_statement_before
            }
          )
        )
      end
    end

    context 'when change set has changed use statement' do
      before do
        change_set.validate(use_statement: new_use_statement)
        instance.update
      end

      let(:new_use_statement) { 'A Changed Use Statement' }

      it 'invokes object client with collection that has new use statement' do
        expect(fake_client).to have_received(:update).with(
          params: cocina_object_with(
            access: {
              copyright: copyright_statement_before,
              license: license_before,
              useAndReproductionStatement: new_use_statement
            }
          )
        )
      end
    end

    context 'when change set has no changes' do
      before do
        instance.update
      end

      it 'invokes object client with collection as before' do
        expect(fake_client).to have_received(:update).with(
          params: cocina_object_with(
            access: {
              copyright: copyright_statement_before,
              license: license_before,
              useAndReproductionStatement: use_statement_before
            }
          )
        )
      end
    end

    context 'when change set has changed APO' do
      before do
        change_set.validate(admin_policy_id: new_apo)
        instance.update
      end

      let(:new_apo) { 'druid:dc123df4569' }

      it 'invokes object client with collection that has new APO' do
        expect(fake_client).to have_received(:update).with(
          params: cocina_object_with(
            administrative: {
              hasAdminPolicy: new_apo
            }
          )
        )
      end
    end
  end
end

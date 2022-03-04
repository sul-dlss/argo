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
    let(:license_before) { 'https://opendatacommons.org/licenses/pddl/1-0/' }
    let(:model) do
      Cocina::Models::DRO.new(
        externalIdentifier: 'druid:bc123df4568',
        label: 'test',
        type: Cocina::Models::Vocab.object,
        version: 1,
        description: {
          title: [{ value: 'test' }],
          purl: 'https://purl.stanford.edu/bc123df4568'
        },
        access: {
          copyright: copyright_statement_before,
          license: license_before,
          useAndReproductionStatement: use_statement_before
        },
        identification: {
          barcode: barcode_before,
          catalogLinks: [{ catalog: 'symphony', catalogRecordId: catkey_before }]
        },
        administrative: { hasAdminPolicy: 'druid:bc123df4569' }
      )
    end
    let(:use_statement_before) { 'My First Use Statement' }
    let(:barcode_before) { '36105014757517' }
    let(:catkey_before) { '367268' }
    let(:change_set) { ItemChangeSet.new(model) }

    before do
      allow(instance).to receive(:object_client).and_return(fake_client)
    end

    context 'when change set has changed copyright statement' do
      let(:new_copyright_statement) { 'A Changed Copyright Statement' }

      before do
        change_set.validate(copyright: new_copyright_statement)
        instance.update
      end

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
      let(:new_license) { 'https://creativecommons.org/licenses/by-nc-nd/3.0/legalcode' }

      before do
        change_set.validate(license: new_license)
        instance.update
      end

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
      let(:new_use_statement) { 'A Changed Use Statement' }

      before do
        change_set.validate(use_statement: new_use_statement)
        instance.update
      end

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

    context 'when change set has changed embargo' do
      let(:new_embargo_release_date) { '2055-07-17' }
      let(:model) do
        Cocina::Models::DRO.new(
          externalIdentifier: 'druid:bc123df4568',
          label: 'test',
          type: Cocina::Models::Vocab.object,
          version: 1,
          description: {
            title: [{ value: 'test' }],
            purl: 'https://purl.stanford.edu/bc123df4568'
          },
          access: {
            embargo: { releaseDate: '2040-04-04', access: 'world', download: 'world' },
            copyright: copyright_statement_before,
            license: license_before,
            useAndReproductionStatement: use_statement_before,
            access: 'dark',
            download: 'none'
          },
          administrative: { hasAdminPolicy: 'druid:bc123df4569' }
        )
      end

      before do
        change_set.validate(embargo_release_date: new_embargo_release_date,
                            embargo_access: 'stanford')
        instance.update
      end

      it 'invokes object client with item/DRO that has new use statement' do
        expect(fake_client).to have_received(:update).with(
          params: a_cocina_object_with_access(
            embargo: {
              releaseDate: DateTime.parse('2055-07-17'),
              access: 'stanford',
              download: 'stanford'
            },
            access: 'dark',
            download: 'none',
            copyright: copyright_statement_before,
            license: license_before,
            useAndReproductionStatement: use_statement_before
          )
        )
      end
    end

    context 'when change set has new embargo' do
      let(:new_embargo_release_date) { '2055-07-17' }
      let(:model) do
        Cocina::Models::DRO.new(
          externalIdentifier: 'druid:bc123df4568',
          label: 'test',
          type: Cocina::Models::Vocab.object,
          version: 1,
          description: {
            title: [{ value: 'test' }],
            purl: 'https://purl.stanford.edu/bc123df4568'
          },
          access: {
            copyright: copyright_statement_before,
            license: license_before,
            useAndReproductionStatement: use_statement_before,
            access: 'dark',
            download: 'none'
          },
          administrative: { hasAdminPolicy: 'druid:bc123df4569' }
        )
      end

      before do
        change_set.validate(embargo_release_date: new_embargo_release_date, embargo_access: 'stanford')
        instance.update
      end

      it 'invokes object client with item/DRO that has new use statement' do
        expect(fake_client).to have_received(:update).with(
          params: a_cocina_object_with_access(
            embargo: { releaseDate: DateTime.parse('2055-07-17'), access: 'stanford', download: 'stanford' },
            access: 'dark',
            download: 'none',
            copyright: copyright_statement_before,
            license: license_before,
            useAndReproductionStatement: use_statement_before
          )
        )
      end
    end

    context 'when change set has one changed property and another nil' do
      let(:model) do
        Cocina::Models::DRO.new(
          externalIdentifier: 'druid:bc123df4568',
          label: 'test',
          type: Cocina::Models::Vocab.object,
          version: 1,
          description: {
            title: [{ value: 'test' }],
            purl: 'https://purl.stanford.edu/bc123df4568'
          },
          access: {
            # NOTE: missing copyright here
            license: license_before,
            useAndReproductionStatement: use_statement_before
          },
          administrative: { hasAdminPolicy: 'druid:bc123df4569' }
        )
      end
      let(:new_use_statement) { 'A Changed Use Statement' }

      before do
        change_set.validate(use_statement: new_use_statement)
        instance.update
      end

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
      before do
        instance.update
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

    context 'when change set has changed barcode' do
      let(:new_barcode) { '36105014757518' }

      before do
        change_set.validate(barcode: new_barcode)
        instance.update
      end

      it 'invokes object client with item/DRO that has new barcode' do
        expect(fake_client).to have_received(:update).with(
          params: a_cocina_object_with_identification(
            barcode: new_barcode,
            catalogLinks: [{ catalog: 'symphony', catalogRecordId: catkey_before }]
          )
        )
      end
    end

    context 'when change set has removed barcode' do
      before do
        change_set.validate(barcode: nil)
        instance.update
      end

      it 'invokes object client with item/DRO that has no barcode' do
        expect(fake_client).to have_received(:update).with(
          params: a_cocina_object_with_identification(
            barcode: nil,
            catalogLinks: [{ catalog: 'symphony', catalogRecordId: catkey_before }]
          )
        )
      end
    end

    context 'when change set has changed catkey' do
      let(:new_catkey) { '367269' }

      before do
        change_set.validate(catkey: new_catkey)
        instance.update
      end

      it 'invokes object client with item/DRO that has new catkey' do
        expect(fake_client).to have_received(:update).with(
          params: a_cocina_object_with_identification(
            barcode: barcode_before,
            catalogLinks: [
              { catalog: 'previous symphony', catalogRecordId: catkey_before },
              { catalog: 'symphony', catalogRecordId: new_catkey }
            ]
          )
        )
      end
    end

    context 'when change set has removed catkey' do
      before do
        change_set.validate(catkey: nil)
        instance.update
      end

      it 'invokes object client with item/DRO that has no catkey' do
        expect(fake_client).to have_received(:update).with(
          params: a_cocina_object_with_identification(
            catalogLinks: [{ catalog: 'previous symphony', catalogRecordId: catkey_before }],
            barcode: barcode_before
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
          params: a_cocina_object_with_administrative(
            hasAdminPolicy: new_apo
          )
        )
      end
    end
  end
end

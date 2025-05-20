# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SerialsForm do
  let(:instance) { described_class.new(cocina_item) }
  let(:druid) { 'druid:bc123df4567' }
  let(:purl) { 'https://purl.stanford.edu/bc123df4567' }
  let(:cocina_item) { build(:dro_with_metadata, id: druid).new(description:, identification:) }

  describe 'loading from cocina' do
    context 'when catalog link contains part label' do
      let(:cocina_item) { build(:dro_with_metadata, id: druid).new(description:, identification:) }
      let(:description) do
        {
          title: [
            {
              structuredValue: [
                { value: 'My Serial', type: 'main title' },
                { value: '7', type: 'part number' },
                { value: 'samurai', type: 'part name' }
              ]
            }
          ],
          note: [
            { value: '1990', type: 'date/sequential designation' }
          ],
          purl:
        }
      end
      let(:identification) do
        {
          catalogLinks: [
            { catalog: 'folio', refresh: true, catalogRecordId: 'a6671606', partLabel: '11 ninjas', sortKey: 'something else' }
          ],
          sourceId: 'sul:1234'
        }
      end

      it 'loads the part label from the catalog link' do
        expect(instance.part_label).to eq '11 ninjas'
        expect(instance.sort_key).to eq 'something else'
      end
    end

    context 'when the catalog link does not contain a part label' do
      let(:cocina_item) { build(:dro_with_metadata, id: druid).new(description:, identification:) }
      let(:description) do
        {
          title: [
            {
              structuredValue: [
                { value: 'My Serial', type: 'main title' },
                { value: 'May 2025', type: 'part number' }
              ]
            }
          ],
          note: [
            { value: '1990', type: 'date/sequential designation' }
          ],
          purl:
        }
      end
      let(:identification) do
        {
          catalogLinks: [
            { catalog: 'folio', refresh: true, catalogRecordId: 'a6671606' }
          ],
          sourceId: 'sul:1234'
        }
      end

      it 'the form is blank' do
        expect(instance.part_label).to be_nil
        expect(instance.sort_key).to be_nil
      end
    end
  end

  describe 'validate and save' do
    let(:description) do
      {
        title: [{ value: 'My Serial' }],
        purl:
      }
    end
    let(:identification) do
      {
        catalogLinks: [
          { catalog: 'folio', refresh: true, catalogRecordId: 'a6671606', partLabel: '7 samurai', sortKey: '2' }
        ],
        sourceId: 'sul:1234'
      }
    end

    before { allow(Repository).to receive(:store) }

    context 'when editing fields' do
      let(:cocina_item) do
        build(:dro_with_metadata, id: druid).new(description:, identification:)
      end

      it 'does validate' do
        expect(instance.validate({ part_label: '7 samurai', sort_key: '2' })).to be true
      end
    end

    context 'when sort_key is set and part_label is not' do
      let(:cocina_item) do
        build(:dro_with_metadata, id: druid).new(description:, identification:)
      end

      it 'does not validate' do
        expect(instance.validate({ part_label: '', sort_key: 'something' })).to be false
      end
    end

    context 'when refresh is false' do
      let(:cocina_item) do
        build(:dro_with_metadata, id: druid).new(identification:, description:)
      end
      let(:identification) do
        {
          catalogLinks: [
            { catalog: 'folio', catalogRecordId: 'a6671606', refresh: false, partLabel: 'a part', sortKey: '1' }
          ],
          sourceId: 'sul:1234'
        }
      end
      let(:expected) do
        build(:dro_with_metadata, id: druid).new(
          description: description,
          identification: {
            catalogLinks: [
              { catalog: 'folio', refresh: false, catalogRecordId: 'a6671606', partLabel: 'a new part', sortKey: '1' }
            ],
            sourceId: 'sul:1234'
          }
        )
      end

      before do
        instance.validate({ part_label: 'a new part', sort_key: '1' })
        instance.save
      end

      it 'keeps refresh as false' do
        expect(Repository).to have_received(:store).with(expected)
      end
    end

    context 'when blank form submitted' do
      let(:cocina_item) do
        build(:dro_with_metadata, id: druid, folio_instance_hrids: ['a6671606']).new(description: description)
      end
      let(:expected) do
        build(:dro_with_metadata, id: druid).new(
          description: description,
          identification: {
            catalogLinks: [
              { catalog: 'folio', partLabel: '', sortKey: '', refresh: true, catalogRecordId: 'a6671606' }
            ],
            sourceId: 'sul:1234'
          }
        )
      end

      before do
        instance.validate({ part_label: '', sort_key: '' })
        instance.save
      end

      it 'retains the existing refresh and removes the labels' do
        expect(Repository).to have_received(:store).with(expected)
      end
    end
  end
end

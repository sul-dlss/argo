# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SerialsForm do
  let(:instance) { described_class.new(cocina_item) }
  let(:druid) { 'druid:bc123df4567' }
  let(:purl) { 'https://purl.stanford.edu/bc123df4567' }
  let(:cocina_item) { build(:dro_with_metadata, id: druid).new(description:) }

  describe 'loading from cocina' do
    context 'when the number is before the part name' do
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

      it 'loads the part label from the title' do
        expect(instance.part_label).to eq '7, samurai'
        expect(instance.sort_key).to eq '1990'
      end
    end

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
            { catalog: 'folio', refresh: false, catalogRecordId: 'a6671606', partLabel: '11 ninjas', sortKey: 'something else' }
          ],
          sourceId: 'sul:1234'
        }
      end

      it 'loads the part label from the title' do
        expect(instance.part_label).to eq '11 ninjas'
        expect(instance.sort_key).to eq 'something else'
      end
    end

    context 'when the number is after the part name' do
      let(:description) do
        {
          title: [
            {
              structuredValue: [
                { value: 'My Serial', type: 'main title' },
                { value: 'samurai', type: 'part name' },
                { value: '7', type: 'part number' }
              ]
            }
          ],
          purl:
        }
      end

      it 'loads the part label from the title' do
        expect(instance.part_label).to eq 'samurai, 7'
        expect(instance.sort_key).to be_nil
      end
    end

    context 'when parallel title' do
      let(:description) do
        {
          title: [
            parallelValue: [
              {
                structuredValue: [
                  { value: 'My Serial', type: 'main title' },
                  { value: '7', type: 'part number' },
                  { value: 'samurai', type: 'part name' }
                ]
              },
              {
                value: 'parallel title'
              }
            ]
          ],
          note: [
            { value: '1990', type: 'date/sequential designation' }
          ],
          purl:
        }
      end

      it 'loads the part label from the first parallel title' do
        expect(instance.part_label).to eq '7, samurai'
        expect(instance.sort_key).to eq '1990'
      end
    end

    context 'when there is no part name' do
      let(:description) do
        {
          title: [
            {
              structuredValue: [
                { value: 'My Serial', type: 'main title' },
                { value: '7', type: 'part number' }
              ]
            }
          ],
          note: [
            { value: '1990', type: 'date/sequential designation' }
          ],
          purl:
        }
      end

      it 'loads the part label, just the number' do
        expect(instance.part_label).to eq '7'
        expect(instance.sort_key).to eq '1990'
      end
    end
  end

  describe 'validate and save' do
    before { allow(Repository).to receive(:store) }

    context 'when the initial title is unstructured' do
      let(:description) do
        {
          title: [{ value: 'My Serial' }],
          purl:
        }
      end
      let(:identification) do
        {
          catalogLinks: [
            { catalog: 'folio', refresh: false, catalogRecordId: 'a6671606', partLabel: '7 samurai', sortKey: 'something' }
          ],
          sourceId: 'sul:1234'
        }
      end

      context 'when part_number is set' do
        let(:cocina_item) do
          build(:dro_with_metadata, id: druid).new(description:, identification:)
        end
        let(:expected) do
          build(:dro_with_metadata, id: druid).new(
            description: {
              title: [
                {
                  structuredValue: [
                    { value: 'My Serial', type: 'main title' },
                    { value: '7 samurai', type: 'part name' }
                  ]
                }
              ],
              note: [{ value: 'something', type: 'date/sequential designation' }],
              purl:
            },
            identification:
          )
        end

        before do
          instance.validate({ part_label: '7 samurai', sort_key: 'something' })
          instance.save
        end

        it 'serializes correctly' do
          expect(Repository).to have_received(:store).with(expected)
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

      context 'when part_number2 is set' do
        let(:expected) do
          build(:dro_with_metadata, id: druid).new(description: {
                                                     title: [
                                                       {
                                                         structuredValue: [
                                                           { value: 'My Serial', type: 'main title' },
                                                           { value: 'samurai 7', type: 'part name' }
                                                         ]
                                                       }
                                                     ],
                                                     note: [{ value: 'something',
                                                              type: 'date/sequential designation' }],
                                                     purl:
                                                   })
        end

        before do
          instance.validate({ part_label: 'samurai 7', sort_key: 'something' })
          instance.save
        end

        it 'serialized correctly' do
          expect(Repository).to have_received(:store).with(expected)
        end
      end
    end

    context 'when the initial title is structured' do
      let(:description) do
        {
          title: [{
            structuredValue: [
              { type: 'subtitle', value: '99' },
              { type: 'main title', value: 'Frog' }
            ]
          }],
          purl:
        }
      end

      let(:expected) do
        build(:dro_with_metadata, id: druid).new(description: {
                                                   title: [
                                                     {
                                                       structuredValue: [
                                                         { type: 'subtitle', value: '99' },
                                                         { type: 'main title', value: 'Frog' },
                                                         { value: '7 samurai', type: 'part name' }
                                                       ]
                                                     }
                                                   ],
                                                   note: [{ value: 'something',
                                                            type: 'date/sequential designation' }],
                                                   purl:
                                                 })
      end

      before do
        instance.validate({ part_label: '7 samurai', sort_key: 'something' })
        instance.save
      end

      it 'serializes correctly' do
        expect(Repository).to have_received(:store).with(expected)
      end
    end

    context 'when parallel title' do
      let(:description) do
        {
          title: [
            {
              parallelValue: [
                {
                  value: 'My Serial'
                },
                {
                  value: 'My Parallel Serial'
                }
              ]
            }
          ],
          purl:
        }
      end

      context 'when part_number is set' do
        let(:expected) do
          build(:dro_with_metadata, id: druid).new(description:
                                                     {
                                                       title: [
                                                         {
                                                           parallelValue: [
                                                             {
                                                               structuredValue: [
                                                                 { value: 'My Serial', type: 'main title' },
                                                                 { value: '7 samurai', type: 'part name' }
                                                               ]
                                                             },
                                                             {
                                                               value: 'My Parallel Serial'
                                                             }
                                                           ]
                                                         }
                                                       ],
                                                       note: [{ value: 'something', type: 'date/sequential designation' }],
                                                       purl:
                                                     })
        end

        before do
          instance.validate({ part_label: '7 samurai', sort_key: 'something' })
          instance.save
        end

        it 'serializes correctly to first parallel title' do
          expect(Repository).to have_received(:store).with(expected)
        end
      end

      context 'when catalog links present' do
        let(:cocina_item) do
          build(:dro_with_metadata, id: druid, folio_instance_hrids: ['a6671606'])
        end
        let(:expected) do
          build(:dro_with_metadata, id: druid).new(
            description: {
              title: [
                {
                  structuredValue: [
                    { value: 'factory DRO title', type: 'main title' }
                  ]
                }
              ],
              purl: 'https://purl.stanford.edu/bc123df4567'
            },
            identification: {
              catalogLinks: [
                { catalog: 'folio', refresh: false, catalogRecordId: 'a6671606', partLabel: '', sortKey: '' }
              ],
              sourceId: 'sul:1234'
            }
          )
        end

        before do
          instance.validate({ part_label: '', sort_key: '' })
          instance.save
        end

        it 'sets refresh to false' do
          expect(Repository).to have_received(:store).with(expected)
        end
      end
    end
  end
end

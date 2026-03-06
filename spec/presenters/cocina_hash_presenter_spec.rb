# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CocinaHashPresenter do
  subject(:presenter) { described_class.new(cocina_object:, without_metadata:) }

  let(:cocina_object) { build(:dro_with_metadata) }
  let(:without_metadata) { false }
  let(:invalid_cocina_hash) do
    {
      cocina_object: build(:dro_with_metadata).to_h.tap do |cocina_object_hash|
        cocina_object_hash[:description].merge!(note: [invalid_note])
      end,
      error_message: 'Multiple value, groupedValue, structuredValue, and parallelValue in description: note1'
    }
  end
  let(:invalid_note) do
    {
      note: [],
      value: 'Relief shown by contours and spot heights',
      appliesTo: [],
      identifier: [],
      groupedValue: [],
      parallelValue: [
        { 'note' => [], 'value' => 'Confidential "Gunji Gokuh" printed on upper right margin', 'appliesTo' => [], 'identifier' => [], 'groupedValue' => [], 'parallelValue' => [], 'structuredValue' => [] },
        { 'note' => [], 'value' => 'Confidential "軍事極祕" printed on upper right margin.', 'appliesTo' => [], 'identifier' => [], 'groupedValue' => [], 'parallelValue' => [], 'structuredValue' => [] }
      ],
      structuredValue: []
    }
  end

  describe '#render' do
    context 'when cocina object has descriptive metadata' do
      # NOTE: You might not see an empty e.g. `structuredValue` array above, but it's there in the instance
      it 'removes empty descriptive elements' do
        expect(presenter.render)
          .to eq(cocinaVersion: Cocina::Models::VERSION,
                 lock: cocina_object.lock,
                 type: 'https://cocina.sul.stanford.edu/models/object',
                 externalIdentifier: cocina_object.externalIdentifier,
                 label: cocina_object.label,
                 version: 1,
                 access: {
                   view: 'dark',
                   download: 'none',
                   controlledDigitalLending: false
                 },
                 administrative: {
                   hasAdminPolicy: 'druid:hv992ry2431'
                 },
                 identification: {
                   catalogLinks: [],
                   sourceId: 'sul:1234'
                 },
                 description: {
                   title: [
                     { value: 'factory DRO title' }
                   ],
                   purl: cocina_object.description.purl
                 },
                 structural: {
                   contains: [],
                   hasMemberOrders: [],
                   isMemberOf: []
                 })
      end
    end

    context 'when without metadata flag is true' do
      let(:without_metadata) { true }

      it 'returns the object without Cocina metadata, e.g., a lock' do
        expect(presenter.render).not_to have_key(:lock)
      end
    end

    context 'when an invalid cocina hash is provided' do
      let(:cocina_object) { invalid_cocina_hash }

      it 'renders the invalid cocina without raising exceptions' do
        expect(presenter.render)
          .to eq(cocina_object: {
                   cocinaVersion: Cocina::Models::VERSION,
                   lock: 'abc123',
                   type: 'https://cocina.sul.stanford.edu/models/object',
                   externalIdentifier: 'druid:bc234fg5678',
                   label: 'factory DRO label',
                   version: 1,
                   access: {
                     view: 'dark',
                     download: 'none',
                     controlledDigitalLending: false
                   },
                   administrative: {
                     hasAdminPolicy: 'druid:hv992ry2431'
                   },
                   identification: {
                     catalogLinks: [],
                     sourceId: 'sul:1234'
                   },
                   description: {
                     title: [
                       {
                         structuredValue: [],
                         parallelValue: [],
                         groupedValue: [],
                         value: 'factory DRO title',
                         identifier: [],
                         note: [],
                         appliesTo: []
                       }
                     ],
                     contributor: [],
                     event: [],
                     form: [],
                     geographic: [],
                     language: [],
                     note: [
                       {
                         note: [],
                         value: 'Relief shown by contours and spot heights',
                         appliesTo: [],
                         identifier: [],
                         groupedValue: [],
                         parallelValue: [
                           {
                             'note' => [],
                             'value' => 'Confidential "Gunji Gokuh" printed on upper right margin',
                             'appliesTo' => [],
                             'identifier' => [],
                             'groupedValue' => [],
                             'parallelValue' => [],
                             'structuredValue' => []
                           },
                           {
                             'note' => [],
                             'value' => 'Confidential "軍事極祕" printed on upper right margin.',
                             'appliesTo' => [],
                             'identifier' => [],
                             'groupedValue' => [],
                             'parallelValue' => [],
                             'structuredValue' => []
                           }
                         ],
                         structuredValue: []
                       }
                     ],
                     identifier: [],
                     subject: [],
                     relatedResource: [],
                     marcEncodedData: [],
                     purl: 'https://purl.stanford.edu/bc234fg5678'
                   },
                   structural: {
                     contains: [],
                     hasMemberOrders: [],
                     isMemberOf: []
                   }
                 },
                 error_message: 'Multiple value, groupedValue, structuredValue, and parallelValue in description: note1')
      end
    end
  end
end

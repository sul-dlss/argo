# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CocinaHashPresenter do
  subject(:presenter) { described_class.new(cocina_object: cocina_object) }

  describe '#render' do
    subject(:rendered) { presenter.render }

    context 'when cocina object lacks descriptive metadata' do
      let(:cocina_object) do
        Cocina::Models::AdminPolicy.new(
          type: Cocina::Models::ObjectType.admin_policy,
          externalIdentifier: 'druid:zt570qh4444',
          version: 1,
          administrative: {
            hasAdminPolicy: 'druid:hv992ry2431',
            hasAgreement: 'druid:hp308wm0436',
            accessTemplate: {}
          },
          label: 'My title'
        )
      end

      it 'returns the object untouched as a hash' do
        expect(rendered).to eq(cocina_object.to_h)
      end
    end

    context 'when cocina object has descriptive metadata' do
      let(:cocina_object) do
        Cocina::Models::Collection.new(
          type: Cocina::Models::ObjectType.collection,
          externalIdentifier: 'druid:zt570qh4444',
          version: 1,
          administrative: { hasAdminPolicy: 'druid:hv992ry2431' },
          label: 'My title',
          description: {
            title: [
              { value: 'My title' }
            ],
            purl: 'https://purl.stanford.edu/zt570qh4444'
          },
          identification: { sourceId: 'sul:1234' },
          access: {}
        )
      end

      # NOTE: You might not see an empty e.g. `structuredValue` array above, but it's there in the instance
      it 'removes empty descriptive elements' do
        expect(rendered).to eq(cocinaVersion: Cocina::Models::VERSION,
                               type: 'https://cocina.sul.stanford.edu/models/collection',
                               externalIdentifier: 'druid:zt570qh4444',
                               label: 'My title',
                               version: 1,
                               access: {
                                 view: 'dark'
                               },
                               administrative: {
                                 hasAdminPolicy: 'druid:hv992ry2431',
                                 releaseTags: []
                               },
                               identification: {
                                 catalogLinks: [],
                                 sourceId: 'sul:1234'
                               },
                               description: {
                                 title: [
                                   { value: 'My title' }
                                 ],
                                 purl: 'https://purl.stanford.edu/zt570qh4444'
                               })
      end
    end
  end
end

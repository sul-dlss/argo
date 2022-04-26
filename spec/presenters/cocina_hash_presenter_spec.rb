# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CocinaHashPresenter do
  subject(:presenter) { described_class.new(cocina_object:, without_metadata:) }

  let(:without_metadata) { false }

  describe '#render' do
    subject(:rendered) { presenter.render }

    context 'when cocina object lacks descriptive metadata' do
      let(:cocina_object) do
        build(:admin_policy_with_metadata, without_description: true)
      end

      it 'returns the object untouched as a hash' do
        expect(rendered).to eq(cocina_object.to_h)
      end
    end

    context 'without metadata' do
      let(:cocina_object) do
        build(:admin_policy_with_metadata, without_description: true)
      end
      let(:without_metadata) { true }

      it 'returns the object without a lock' do
        expect(rendered).to eq(cocina_object.to_h.except(:lock))
      end
    end

    context 'when cocina object has descriptive metadata' do
      let(:cocina_object) do
        build(:collection_with_metadata)
      end

      # NOTE: You might not see an empty e.g. `structuredValue` array above, but it's there in the instance
      it 'removes empty descriptive elements' do
        expect(rendered).to eq(cocinaVersion: Cocina::Models::VERSION,
                               lock: cocina_object.lock,
                               type: 'https://cocina.sul.stanford.edu/models/collection',
                               externalIdentifier: cocina_object.externalIdentifier,
                               label: cocina_object.label,
                               version: 1,
                               access: {
                                 view: 'dark'
                               },
                               administrative: {
                                 hasAdminPolicy: 'druid:hv992ry2431',
                                 releaseTags: []
                               },
                               identification: {
                                 catalogLinks: []
                               },
                               description: {
                                 title: [
                                   { value: cocina_object.label }
                                 ],
                                 purl: cocina_object.description.purl
                               })
      end
    end
  end
end

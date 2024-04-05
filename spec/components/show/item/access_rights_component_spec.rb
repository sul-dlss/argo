# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Show::Item::AccessRightsComponent, type: :component do
  let(:component) { described_class.new(change_set:, state_service:) }
  let(:change_set) { ItemChangeSet.new(cocina) }
  let(:cocina) do
    Cocina::Models::DRO.new(externalIdentifier: 'druid:bc234fg5678',
                            type: Cocina::Models::ObjectType.document,
                            label: 'my dro',
                            version: 1,
                            description: {
                              title: [{ value: 'my dro' }],
                              purl: 'https://purl.stanford.edu/bc234fg5678'
                            },
                            access:,
                            administrative: {
                              hasAdminPolicy: 'druid:hv992ry2431'
                            },
                            identification: { sourceId: 'sul:1234' },
                            structural: {})
  end
  let(:rendered) { render_inline(component) }
  let(:open) { true }
  let(:state_service) { instance_double(StateService, open?: open) }

  context 'with view location' do
    let(:access) do
      { view: 'location-based', download: 'none', location: 'm&m' }
    end

    it 'shows the description' do
      expect(rendered.to_html).to include 'View: Location: m&amp;m, Download: None'
    end
  end

  context 'with download location' do
    let(:access) do
      { view: 'world', download: 'location-based', location: 'm&m' }
    end

    it 'shows the description' do
      expect(rendered.to_html).to include 'View: World, Download: Location: m&amp;m'
    end
  end
end

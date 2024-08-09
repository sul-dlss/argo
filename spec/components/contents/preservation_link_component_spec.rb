# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Contents::PreservationLinkComponent, type: :component do
  let(:druid) { 'druid:bc123df4567' }
  let(:cocina_file) do
    Cocina::Models::File.new(type: Cocina::Models::ObjectType.file,
                             filename: 'example.tif',
                             label: 'example.tif',
                             externalIdentifier: 'https://cocina.sul.stanford.edu/file/b7cdfa7a-6e1f-484b-bbb0-f9a46c40dbb4',
                             hasMimeType: 'image/tiff',
                             version: 3,
                             access: {
                               view: 'world',
                               download: 'world'
                             },
                             administrative: {
                               publish: true,
                               sdrPreserve: preserved,
                               shelve: true
                             })
  end
  let(:preserved) { true }

  describe 'when accessioned and preserved' do
    it 'renders download link' do
      render_inline(described_class.new(cocina_file:, druid:, version: 2))

      expect(page).to have_text('Preservation')
      expect(page).to have_link('/items/druid:bc123df4567/files/example.tif/preserved?version=2', href: '/items/druid:bc123df4567/files/example.tif/preserved?version=2')
    end
  end

  describe 'when not accessioned' do
    it 'does not render' do
      render_inline(described_class.new(cocina_file:, druid:, version: nil))

      expect(page).to have_no_text('Preservation')
    end
  end

  describe 'when not preserved' do
    let(:preserved) { false }

    it 'does not render' do
      render_inline(described_class.new(cocina_file:, druid:, version: 2))

      expect(page).to have_no_text('Preservation')
    end
  end
end

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Contents::StacksLinkComponent, type: :component do
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
                               download:
                             },
                             administrative: {
                               publish: true,
                               sdrPreserve: true,
                               shelve:
                             })
  end

  let(:download) { 'world' }
  let(:shelve) { true }
  let(:user_version) { nil }

  let(:stacks_url) { 'https://stacks-test.stanford.edu/file/druid:bc123df4567/example.tif' }

  context 'when shelved and downloadable' do
    it 'renders download link' do
      render_inline(described_class.new(cocina_file:, druid:, user_version:))

      expect(page).to have_text('Stacks')
      expect(page).to have_link(stacks_url, href: stacks_url)
    end
  end

  context 'with user version' do
    let(:user_version) { 2 }

    let(:stacks_url) { 'https://stacks-test.stanford.edu/v2/file/bc123df4567/version/2/example.tif' }

    it 'renders download link' do
      render_inline(described_class.new(cocina_file:, druid:, user_version:))

      expect(page).to have_text('Stacks')
      expect(page).to have_link(stacks_url, href: stacks_url)
    end
  end

  context 'when shelved but not downloadable' do
    let(:download) { 'none' }

    it 'does not render download link' do
      render_inline(described_class.new(cocina_file:, druid:, user_version:))

      expect(page).to have_text('Stacks')
      expect(page).to have_text('not available for download')
      expect(page).to have_no_link(stacks_url, href: stacks_url)
    end
  end

  context 'when not shelved' do
    let(:shelve) { false }

    it 'does not render' do
      render_inline(described_class.new(cocina_file:, druid:, user_version:))

      expect(page).to have_no_text('Stacks')
    end
  end
end

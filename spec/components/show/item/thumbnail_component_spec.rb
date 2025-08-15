# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Show::Item::ThumbnailComponent, type: :component do
  let(:component) { described_class.new(document:) }
  let(:rendered) { render_inline(component) }

  let(:document) do
    SolrDocument.new('id' => 'druid:kv840xx0000',
                     SolrDocument::FIELD_TITLE => title,
                     SolrDocument::FIELD_OBJECT_TYPE => object_type,
                     'first_shelved_image_ss' => thumbnail)
  end

  context 'without a thumbnail_url and a long title' do
    let(:title) do
      'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Proin dolor mauris, ' \
        'tincidunt ut elementum sollicitudin, luctus sit amet quam. Interdum et ' \
        'malesuada fames ac ante ipsum primis in faucibus.  Proin maximus, urna id ' \
        'gravida sodales, dui ex ullamcorper ante, vestibulum consectetur odio arcu ' \
        'mattis dolor. '
    end
    let(:thumbnail) { nil }
    let(:object_type) { 'image' }

    it 'truncates the title' do
      expect(rendered.to_html).to include 'gravida sodales, dui ex…'
    end
  end

  context 'with a thumbnail_url' do
    let(:title) { 'a very cool title' }
    let(:thumbnail) { 'something.jpg' }

    context 'with object_type == file' do
      let(:object_type) { 'file' }

      it 'does not render the thumbnail' do
        expect(rendered.to_html).not_to include 'something/full/!400,400/0/default.jpg'
        expect(rendered.to_html).to include title
      end
    end

    context 'with object_type == image' do
      let(:object_type) { 'image' }

      it 'renders the thumbnail' do
        expect(rendered.to_html).to include 'something/full/!400,400/0/default.jpg'
        expect(rendered.to_html).not_to include title
      end
    end
  end
end

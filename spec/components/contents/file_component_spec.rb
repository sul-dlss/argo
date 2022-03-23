# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Contents::FileComponent, type: :component do
  let(:component) { described_class.new(file: file, object_id: 'druid:kb487gt5106', viewable: true, image: true) }
  let(:rendered) { render_inline(component) }

  let(:file) { build(:managed_file, :transcription, height: 11_839, width: 19_380, filename: 'example.tif') }

  context 'with an image fileset' do
    it 'renders the component' do
      expect(rendered.css('a[href="/items/druid:kb487gt5106/files?id=example.tif"]').to_html)
        .to include('example.tif')
      expect(rendered.to_html).to include 'World'
      expect(rendered.to_html).to include 'Stanford'
      expect(rendered.to_html).to include 'Transcription'
      expect(rendered.to_html).to include '11839 px'
    end
  end

  context 'with no file use set' do
    let(:file) { build(:managed_file) }

    it 'renders the component' do
      expect(rendered.to_html).to include 'No role'
    end
  end

  context 'with no presentation' do
    let(:presentation) { nil }

    it 'renders the component' do
      expect(rendered.to_html).to include 'World'
    end
  end

  context 'with a fileset that is not an image' do
    let(:component) { described_class.new(file: file, object_id: 'druid:kb487gt5106', viewable: true, image: false) }

    it 'renders the component without height' do
      expect(rendered.to_html).to include 'World'
      expect(rendered.to_html).not_to include '11839 px'
    end
  end
end

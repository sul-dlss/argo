# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Contents::FileComponent, type: :component do
  let(:component) { described_class.new(file: file, object_id: 'druid:kb487gt5106', viewable: true) }
  let(:rendered) { render_inline(component) }
  let(:file) do
    instance_double(Cocina::Models::File,
                    filename: '0220_MLK_Kids_Gadson_459-25.tif',
                    externalIdentifier: 'https://cocina.sul.stanford.edu/file/b7cdfa7a-6e1f-484b-bbb0-f9a46c40dbb4',
                    hasMimeType: 'image/tiff',
                    size: 99,
                    access: access,
                    administrative: admin,
                    use: use)
  end

  let(:access) { instance_double(Cocina::Models::FileAccess, view: 'world', download: 'stanford') }
  let(:admin) { instance_double(Cocina::Models::FileAdministrative, sdrPreserve: true, publish: true, shelve: true) }
  let(:use) { 'transcription' }

  it 'renders the component' do
    expect(rendered.css('a[href="/items/druid:kb487gt5106/files?id=0220_MLK_Kids_Gadson_459-25.tif"]').to_html)
      .to include('0220_MLK_Kids_Gadson_459-25.tif')
    expect(rendered.to_html).to include 'World'
    expect(rendered.to_html).to include 'Stanford'
    expect(rendered.to_html).to include 'Transcription'
  end

  context 'with no file use set' do
    let(:use) { nil }

    it 'renders the component' do
      expect(rendered.to_html).to include 'No role'
    end
  end
end

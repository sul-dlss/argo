# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Contents::ResourceComponent, type: :component do
  let(:component) do
    described_class.new(resource: resource,
                        resource_counter: 1,
                        counter_offset: 50,
                        object_id: 'druid:kb487gt5106',
                        viewable: true)
  end
  let(:rendered) { render_inline(component) }
  let(:resource) do
    instance_double(Cocina::Models::FileSet,
                    type: type,
                    externalIdentifier: 'https://cocina.sul.stanford.edu/fileSet/bb573tm8486-bc91c072-3b0f-4338-a9b2-0f85e1b98e00',
                    version: 3,
                    label: 'Object 1',
                    structural: instance_double(Cocina::Models::FileSetStructural, contains: [file]))
  end
  let(:file) do
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
                               sdrPreserve: true,
                               shelve: true
                             },
                             presentation: presentation)
  end
  let(:type) { 'https://cocina.sul.stanford.edu/models/resources/image' }
  let(:presentation) { { height: 11_839, width: 19_380 } }

  context 'with an image' do
    it 'renders the component' do
      expect(rendered.to_html).to include 'Resource (51)'
      expect(rendered.to_html).to include 'Type'
      expect(rendered.to_html).to include 'Height'
      expect(rendered.to_html).to include 'Width'
    end
  end

  context 'with no presentation' do
    let(:presentation) { nil }

    it 'renders the component' do
      expect(rendered.to_html).to include 'Height'
    end
  end

  context 'when fileset is not an image' do
    let(:type) { 'https://cocina.sul.stanford.edu/models/resources/file' }

    it 'height column does not display' do
      expect(rendered.to_html).not_to include 'Height'
    end
  end
end

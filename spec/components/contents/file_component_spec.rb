# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Contents::FileComponent, type: :component do
  let(:component) { described_class.new(file: file, viewable: true) }
  let(:rendered) { render_inline(component) }
  let(:file) do
    instance_double(Cocina::Models::File,
                    filename: '0220_MLK_Kids_Gadson_459-25.tif',
                    externalIdentifier: 'druid:kb487gt5106/0220_MLK_Kids_Gadson_459-25.tif',
                    hasMimeType: 'image/tiff',
                    size: 99,
                    access: access,
                    administrative: admin)
  end

  let(:access) { instance_double(Cocina::Models::FileAccess, access: 'world') }
  let(:admin) { instance_double(Cocina::Models::FileAdministrative, sdrPreserve: true, shelve: true) }

  it 'renders the component' do
    expect(rendered.css('a[href="/items/druid:kb487gt5106/files?id=0220_MLK_Kids_Gadson_459-25.tif"]').to_html)
      .to include('0220_MLK_Kids_Gadson_459-25.tif')
  end
end

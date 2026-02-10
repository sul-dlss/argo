# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Contents::StructuralComponent, type: :component do
  let(:component) do
    described_class.new(structural: Cocina::Models::DROStructural.new(contains:, hasMemberOrders: member_orders),
                        viewable: true,
                        item_id: 'druid:kb487gt5106',
                        user_version: nil)
  end
  let(:rendered) { render_inline(component) }
  let(:contains) do
    [
      Cocina::Models::FileSet.new(
        type: Cocina::Models::FileSetType.file,
        externalIdentifier: 'https://cocina.sul.stanford.edu/fileSet/bb573tm8486-bc91c072-3b0f-4338-a9b2-0f85e1b98e00',
        version: 1,
        label: 'Image 1',
        structural: {
          contains: [
            Cocina::Models::File.new(
              type: Cocina::Models::ObjectType.file,
              filename: 'example.tif',
              label: 'example.tif',
              externalIdentifier: 'https://cocina.sul.stanford.edu/file/b7cdfa7a-6e1f-484b-bbb0-f9a46c40dbb4',
              hasMimeType: 'image/tiff',
              version: 1,
              access: {
                view: 'world',
                download: 'world'
              },
              administrative: {
                publish: true,
                sdrPreserve: true,
                shelve: true
              }
            )
          ]
        }
      ),
      Cocina::Models::FileSet.new(
        type: Cocina::Models::FileSetType.file,
        externalIdentifier: 'https://cocina.sul.stanford.edu/fileSet/bb573tm8486-bc91c072-3b0f-4338-a9b2-0f85e1b98e11',
        version: 2,
        label: 'Image 2',
        structural: {
          contains: [
            Cocina::Models::File.new(
              type: Cocina::Models::ObjectType.file,
              filename: 'example2.tif',
              label: 'example2.tif',
              externalIdentifier: 'https://cocina.sul.stanford.edu/file/b7cdfa7a-6e1f-484b-bbb0-f9a46c40dbc5',
              hasMimeType: 'image/tiff',
              version: 2,
              access: {
                view: 'world',
                download: 'world'
              },
              administrative: {
                publish: true,
                sdrPreserve: true,
                shelve: true
              }
            )
          ]
        }
      )
    ]
  end
  let(:member_orders) { [] }

  # NOTE: We're considering self-depositish ("simple") items, which have no member
  # orders, the happy path for this test.
  it 'renders the component with the resource label' do
    expect(rendered.to_html).to include('2 Resources')
  end

  # NOTE: This is the structure of book-like items.
  context 'with a member order containing no members' do
    let(:member_orders) do
      [
        {
          members: [],
          viewingDirection: 'left-to-right'
        }
      ]
    end

    it 'renders the component with the resource label' do
      expect(rendered.to_html).to include('2 Resources')
    end
  end

  context 'with a virtual object' do
    let(:member_orders) do
      [
        {
          members: %w[druid:ry482gj6267 druid:cd655zh4100 druid:bc123df4567]
        }
      ]
    end

    it 'renders the component with the constituent label' do
      expect(rendered.to_html).to include('3 Constituents')
    end
  end
end

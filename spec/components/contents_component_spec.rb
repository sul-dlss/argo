# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ContentsComponent, type: :component do
  let(:presenter) do
    instance_double(ArgoShowPresenter,
                    document: solr_doc,
                    cocina:,
                    view_token: 'skret-t0k3n',
                    open_and_not_assembling?: open,
                    user_version_view: user_version,
                    user_version_view?: user_version.present?,
                    version_view: version,
                    version_view?: version.present?,
                    version_or_user_version_view?: version.present? || user_version.present?)
  end
  let(:user_version) { nil }
  let(:version) { nil }
  let(:component) { described_class.new(presenter:) }

  let(:rendered) { render_inline(component) }

  context 'with an Item' do
    let(:solr_doc) do
      SolrDocument.new(id: 'druid:bb000zn0114')
    end
    let(:cocina) { build(:dro).new(structural:) }
    let(:structural) { Cocina::Models::DROStructural.new(contains:, hasMemberOrders: member_orders, isMemberOf: []) }
    let(:member_orders) { [] }
    let(:contains) { [] }

    before do
      allow(vc_test_controller).to receive(:can?).and_return(true)
    end

    context 'with unlocked object with no attached resources' do
      let(:open) { true }

      it 'renders a turbo frame' do
        expect(rendered.css('turbo-frame').first['src']).to eq '/items/skret-t0k3n/structure'
      end

      it 'shows Upload CSV button' do
        expect(rendered.css('.bi-upload')).not_to be_present
      end

      it 'does not show the Download CSV button' do
        expect(rendered.css('.bi-download')).not_to be_present
      end
    end

    context 'with unlocked object with an attached resources' do
      let(:open) { true }
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
                    view: 'dark'
                  },
                  administrative: {
                    publish: true,
                    sdrPreserve: true,
                    shelve: false
                  }
                )
              ]
            }
          )
        ]
      end

      it 'renders a turbo frame' do
        expect(rendered.css('turbo-frame').first['src']).to eq '/items/skret-t0k3n/structure'
      end

      it 'shows Upload CSV button' do
        expect(rendered.css('.bi-upload')).to be_present
      end

      it 'shows Download CSV button' do
        expect(rendered.css('.bi-download')).to be_present
      end
    end

    context 'with locked object' do
      let(:open) { false }

      it 'hides Upload CSV button' do
        expect(rendered.css('.bi-upload')).not_to be_present
      end
    end

    context 'when a user version' do
      let(:open) { true }
      let(:user_version) { 2 }

      it 'hides Upload CSV button' do
        expect(rendered.css('.bi-upload')).not_to be_present
      end

      it 'hides Download CSV button' do
        expect(rendered.css('.bi-download')).not_to be_present
      end
    end

    context 'when a version' do
      let(:open) { true }
      let(:version) { 2 }

      it 'hides Upload CSV button' do
        expect(rendered.css('.bi-upload')).not_to be_present
      end

      it 'hides Download CSV button' do
        expect(rendered.css('.bi-download')).not_to be_present
      end
    end

    context 'with a virtual object' do
      let(:open) { true }
      let(:member_orders) do
        [
          {
            members: %w[druid:ry482gj6267 druid:cd655zh4100 druid:bc123df4567]
          }
        ]
      end

      it 'does not show the Upload CSV button' do
        expect(rendered.css('.bi-upload')).not_to be_present
      end

      it 'does not shows the download CSV button' do
        expect(rendered.css('.bi-download')).not_to be_present
      end
    end
  end
end

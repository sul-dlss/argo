# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ContentsComponent, type: :component do
  let(:presenter) do
    instance_double(ArgoShowPresenter,
                    document: solr_doc,
                    cocina:,
                    view_token: 'skret-t0k3n',
                    open_and_not_assembling?: open,
                    user_version:,
                    user_version_view?: user_version_view)
  end
  let(:user_version) { nil }
  let(:user_version_view) { false }
  let(:component) { described_class.new(presenter:) }

  let(:rendered) { render_inline(component) }

  context 'with an Item' do
    let(:solr_doc) do
      SolrDocument.new(id: 'druid:bb000zn0114')
    end
    let(:cocina) { build(:dro) }

    before do
      allow(controller).to receive(:can?).and_return(true)
    end

    context 'with unlocked object' do
      let(:open) { true }

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
      let(:user_version_view) { true }

      it 'hides Upload CSV button' do
        expect(rendered.css('.bi-upload')).not_to be_present
      end

      it 'hides Download CSV button' do
        expect(rendered.css('.bi-download')).not_to be_present
      end
    end
  end
end

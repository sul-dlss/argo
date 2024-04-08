# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ContentsComponent, type: :component do
  let(:presenter) do
    instance_double(ArgoShowPresenter,
                    document: solr_doc, cocina:,
                    view_token: 'skret-t0k3n',
                    open?: open)
  end
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
    end

    context 'with locked object' do
      let(:open) { false }

      it 'hides Upload CSV button' do
        expect(rendered.css('.bi-upload')).not_to be_present
      end
    end
  end
end

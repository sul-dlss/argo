# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Show::ExternalLinksComponent, type: :component do
  before do
    render_inline(described_class.new(document: document))
  end

  context 'for a admin policy' do
    let(:document) do
      instance_double(SolrDocument, id: 'druid:ab123cd3445',
                                    to_param: 'druid:ab123cd3445',
                                    druid: 'ab123cd3445',
                                    admin_policy?: true)
    end

    it 'links to Solr and Cocina' do
      expect(page).not_to have_link 'SearchWorks'
      expect(page).not_to have_link 'PURL'
      expect(page).to have_link 'Solr document', href: '/view/druid:ab123cd3445.json'
      expect(page).to have_link 'Cocina model', href: '/items/druid:ab123cd3445.json'
    end
  end

  context 'for a DRO' do
    let(:document) do
      instance_double(SolrDocument, id: 'druid:ab123cd3445',
                                    to_param: 'druid:ab123cd3445',
                                    druid: 'ab123cd3445',
                                    admin_policy?: false,
                                    catkey: catkey, released_to: released_to)
    end
    let(:catkey) { nil }

    let(:released_to) do
      []
    end

    context 'when not released' do
      it 'links to purl and the Solr document' do
        expect(page).not_to have_link 'SearchWorks'
        expect(page).to have_link 'PURL', href: 'https://sul-purl-stage.stanford.edu/ab123cd3445'
        expect(page).to have_link 'Solr document', href: '/view/druid:ab123cd3445.json'
        expect(page).to have_link 'Cocina model', href: '/items/druid:ab123cd3445.json'
      end
    end

    context 'when released to SearchWorks' do
      let(:released_to) do
        ['Searchworks']
      end

      context 'with a catkey' do
        let(:catkey) { '123456' }

        it 'links to searchworks with the catkey and links to purl' do
          expect(page).to have_link 'SearchWorks', href: 'http://searchworks.stanford.edu/view/123456'
          expect(page).to have_link 'PURL', href: 'https://sul-purl-stage.stanford.edu/ab123cd3445'
          expect(page).to have_link 'Cocina model', href: '/items/druid:ab123cd3445.json'
        end
      end

      context 'without a catkey' do
        let(:catkey) { nil }

        it 'links to searchworks using a druid' do
          expect(page).to have_link 'SearchWorks', href: 'http://searchworks.stanford.edu/view/ab123cd3445'
        end
      end
    end
  end
end

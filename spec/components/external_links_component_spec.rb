# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ExternalLinksComponent, type: :component do
  let(:document) do
    instance_double(SolrDocument, id: 'druid:ab123cd3445',
                                  to_param: 'druid:ab123cd3445',
                                  druid: 'ab123cd3445',
                                  catkey: catkey, released_to: released_to, dor_services_version: '9.0.0')
  end
  let(:catkey) { nil }

  let(:released_to) do
    []
  end

  context 'when not released' do
    it 'links to purl and the Solr document' do
      render_inline(described_class.new(document: document))

      expect(page).not_to have_link 'Searchworks'
      expect(page).to have_link 'PURL', href: 'https://sul-purl-test.stanford.edu/ab123cd3445'
      expect(page).to have_link 'Solr document', href: '/view/druid:ab123cd3445.json'
    end
  end

  context 'when released to Searchworks' do
    let(:released_to) do
      ['Searchworks']
    end

    context 'with a catkey' do
      let(:catkey) { '123456' }

      it 'links to searchworks with the catkey and links to purl' do
        render_inline(described_class.new(document: document))

        expect(page).to have_link 'Searchworks', href: 'http://searchworks.stanford.edu/view/123456'
        expect(page).to have_link 'PURL', href: 'https://sul-purl-test.stanford.edu/ab123cd3445'
      end
    end

    context 'without a catkey' do
      let(:catkey) { nil }

      it 'links to searchworks using a druid' do
        render_inline(described_class.new(document: document))

        expect(page).to have_link 'Searchworks', href: 'http://searchworks.stanford.edu/view/ab123cd3445'
      end
    end
  end
end

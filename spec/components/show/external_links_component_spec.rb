# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Show::ExternalLinksComponent, type: :component do
  before do
    render_inline(described_class.new(document:, presenter:))
  end

  let(:presenter) { instance_double(ArgoShowPresenter, user_version_view?: user_version_view, user_version: 2) }

  let(:user_version_view) { false }

  context 'for a non-publishable item (adminPolicy)' do
    let(:document) do
      instance_double(SolrDocument, id: 'druid:ab123cd3445',
                                    to_param: 'druid:ab123cd3445',
                                    druid: 'ab123cd3445',
                                    publishable?: false)
    end
    let(:presenter) { instance_double(ArgoShowPresenter, user_version_view?: user_version_view, user_version:) }
    let(:user_version_view) { false }
    let(:user_version) { nil }

    it 'links to Solr and Cocina' do
      expect(page).to have_no_link 'SearchWorks'
      expect(page).to have_no_link 'Description'
      expect(page).to have_no_link 'PURL'
      expect(page).to have_no_link 'Dublin Core'

      expect(page).to have_link 'Solr document', href: '/view/druid:ab123cd3445.json'
      expect(page).to have_link 'Cocina model', href: '/items/druid:ab123cd3445.json'
    end
  end

  context 'for a publishable item (DRO)' do
    let(:document) do
      instance_double(SolrDocument, id: 'druid:ab123cd3445',
                                    to_param: 'druid:ab123cd3445',
                                    druid: 'ab123cd3445',
                                    publishable?: true,
                                    catalog_record_id:, released_to:)
    end
    let(:presenter) { instance_double(ArgoShowPresenter, user_version_view?: user_version_view, user_version:) }
    let(:user_version_view) { false }
    let(:user_version) { 2 }
    let(:catalog_record_id) { nil }
    let(:released_to) do
      []
    end

    context 'when not released' do
      it 'links to purl and the Solr document' do
        expect(page).to have_no_link 'SearchWorks'
        expect(page).to have_link 'Description', href: '/items/druid:ab123cd3445/metadata/descriptive'
        expect(page).to have_link 'PURL', href: 'https://sul-purl-stage.stanford.edu/ab123cd3445'
        expect(page).to have_link 'Solr document', href: '/view/druid:ab123cd3445.json'
        expect(page).to have_link 'Cocina model', href: '/items/druid:ab123cd3445.json'
      end
    end

    context 'when released to SearchWorks' do
      let(:released_to) do
        ['Searchworks']
      end

      context 'with a catalog record ID' do
        let(:catalog_record_id) { '123456' }

        it 'links to searchworks with the catalog record ID and links to purl' do
          expect(page).to have_link 'SearchWorks', href: 'http://searchworks.stanford.edu/view/123456'
          expect(page).to have_link 'PURL', href: 'https://sul-purl-stage.stanford.edu/ab123cd3445'
          expect(page).to have_link 'Cocina model', href: '/items/druid:ab123cd3445.json'
        end
      end

      context 'without a catalog record ID' do
        let(:catalog_record_id) { nil }

        it 'links to searchworks using a druid' do
          expect(page).to have_link 'SearchWorks', href: 'http://searchworks.stanford.edu/view/ab123cd3445'
        end
      end

      context 'when a user version view' do
        let(:user_version_view) { true }

        it 'links to user version' do
          expect(page).to have_link 'Cocina model', href: '/items/druid:ab123cd3445/user_versions/2.json'
        end
      end
    end

    context 'when a user version' do
      let(:user_version_view) { true }
      let(:user_version) { 2 }

      it 'links to user version descriptive metadata' do
        expect(page).to have_link 'Description', href: '/items/druid:ab123cd3445/user_versions/2/metadata/descriptive'
      end
    end
  end
end

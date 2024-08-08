# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Show::ExternalLinksComponent, type: :component do
  before do
    render_inline(described_class.new(document:, presenter:))
  end

  let(:presenter) do
    instance_double(ArgoShowPresenter, user_version_view?: user_version.present?, user_version_view: user_version,
                                       version_view: version, version_view?: version.present?, previous_user_version_view?: false)
  end

  let(:user_version) { nil }
  let(:version) { nil }

  context 'for a non-publishable item (adminPolicy)' do
    let(:document) do
      instance_double(SolrDocument, id: 'druid:ab123cd3445',
                                    to_param: 'druid:ab123cd3445',
                                    druid: 'ab123cd3445',
                                    publishable?: false)
    end

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
        let(:user_version) { 2 }

        it 'links to user version' do
          expect(page).to have_link 'Cocina model', href: '/items/druid:ab123cd3445/user_versions/2.json'
        end
      end

      context 'when a version view' do
        let(:version) { 3 }

        it 'links to user version' do
          expect(page).to have_link 'Cocina model', href: '/items/druid:ab123cd3445/versions/3.json'
        end
      end
    end

    context 'when the head user version' do
      let(:user_version) { 2 }
      let(:presenter) do
        instance_double(ArgoShowPresenter, user_version_view?: user_version.present?, user_version_view: user_version,
                                           version_view: version, version_view?: version.present?, previous_user_version_view?: false)
      end

      it 'links to user version descriptive metadata' do
        expect(page).to have_link 'Description', href: '/items/druid:ab123cd3445/user_versions/2/metadata/descriptive'
      end

      it 'links to base PURL' do
        expect(page).to have_link 'PURL', href: 'https://sul-purl-stage.stanford.edu/ab123cd3445'
      end
    end

    context 'when a previous user version' do
      let(:user_version) { 1 }
      let(:head_user_version) { 2 }
      let(:version) { 1 }
      let(:presenter) do
        instance_double(ArgoShowPresenter, user_version_view?: user_version.present?, user_version_view: user_version,
                                           version_view: version, version_view?: version.present?,
                                           previous_user_version_view?: user_version.present? && user_version != head_user_version)
      end

      it 'links to versioned PURL' do
        expect(page).to have_link 'PURL', href: 'https://sul-purl-stage.stanford.edu/ab123cd3445/version/1'
      end
    end

    context 'when a version' do
      let(:version) { 3 }

      it 'links to version descriptive metadata' do
        expect(page).to have_link 'Description', href: '/items/druid:ab123cd3445/versions/3/metadata/descriptive'
      end
    end
  end
end

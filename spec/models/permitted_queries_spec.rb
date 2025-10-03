# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PermittedQueries do
  let(:user) { User.new(sunetid: 'test_user') }

  describe '#permitted_apos' do
    context 'with large Solr query' do
      let(:many_groups) { (0..30).map { |num| "workgroup:workgroup_#{num}" } }

      it 'does not raise an RSolr::Error::Http-413 Request Entity Too Large' do
        user.set_groups_to_impersonate many_groups
        expect { user.permitted_apos }.not_to raise_error
        expect(user.permitted_apos).to be_an Array
      end
    end

    context 'for personal workgroups' do
      it 'does not raise an RSolr syntax error' do
        user.set_groups_to_impersonate ['~sunetid:somegroup']
        expect { user.permitted_apos }.not_to raise_error
        expect(user.permitted_apos).to be_an Array
      end
    end
  end

  describe '#permitted_collections' do
    context 'with large Solr query' do
      let(:many_groups) { (0..30).map { |num| "workgroup:workgroup_#{num}" } }

      it 'does not raise an RSolr::Error::Http-413 Request Entity Too Large' do
        user.set_groups_to_impersonate many_groups
        expect { user.permitted_collections }.not_to raise_error
        expect(user.permitted_collections).to be_an Array
      end
    end

    context 'with inactive collections' do
      let(:blacklight_config) { CatalogController.blacklight_config }
      let(:solr_conn) { blacklight_config.repository_class.new(blacklight_config).connection }
      let(:service) { described_class.new([], [], true) }

      before do
        solr_conn.delete_by_query("#{SolrDocument::FIELD_OBJECT_TYPE}:collection")
        solr_conn.add(id: 'druid:bg444xg6666', SolrDocument::FIELD_OBJECT_TYPE => 'collection',
                      display_title_ss: 'Inactive collection', tag_ssim: PermittedQueries::INACTIVE_TAG)
        solr_conn.add(id: 'druid:bg555xg7777', SolrDocument::FIELD_OBJECT_TYPE => 'collection', display_title_ss: 'My collection')
        solr_conn.commit
      end

      it 'returns an array' do
        expect(service.permitted_collections).to eq [['None', ''], [
          'My collection (druid:bg555xg7777)',
          'druid:bg555xg7777'
        ]]
      end
    end
  end
end

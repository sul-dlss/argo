# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PermittedQueries do
  let(:user) { User.new(sunetid: 'test_user') }

  describe '#permitted_apos' do
    let(:many_groups) { (0..30).map { |num| "workgroup:workgroup_#{num}" } }

    context 'with large Solr query' do
      it 'does not raise an RSolr::Error::Http-413 Request Entity Too Large' do
        user.set_groups_to_impersonate many_groups
        expect { user.permitted_apos }.not_to raise_error
        expect(user.permitted_apos).to be_an Array
      end
    end

    context 'personal workgroups' do
      it 'does not raise an RSolr syntax error' do
        user.set_groups_to_impersonate ['~sunetid:somegroup']
        expect { user.permitted_apos }.not_to raise_error
        expect(user.permitted_apos).to be_an Array
      end
    end
  end

  describe '#permitted_collections' do
    let(:many_groups) { (0..30).map { |num| "workgroup:workgroup_#{num}" } }

    context 'with large Solr query' do
      it 'does not raise an RSolr::Error::Http-413 Request Entity Too Large' do
        user.set_groups_to_impersonate many_groups
        expect { user.permitted_collections }.not_to raise_error
        expect(user.permitted_collections).to be_an Array
      end
    end

    it 'returns an array' do
      expect(user.permitted_collections).to eq [['None', '']]
    end
  end
end

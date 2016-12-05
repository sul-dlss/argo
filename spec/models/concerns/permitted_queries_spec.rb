require 'spec_helper'

RSpec.describe PermittedQueries do
  describe '#permitted_apos' do
    let(:user) { User.find_or_create_by_remoteuser 'test_user' }
    let(:many_groups) { (0..30).map { |num| "workgroup:workgroup_#{num}" } }
    context 'with large Solr query' do
      it 'does not raise an RSolr::Error::Http-413 Request Entity Too Large' do
        user.set_groups_to_impersonate many_groups
        expect{user.permitted_apos}.to_not raise_error
        expect(user.permitted_apos).to be_an Array
      end
    end

    context 'personal workgroups' do
      it 'does not raise an RSolr syntax error' do
        user.set_groups_to_impersonate ['~sunetid:somegroup']
        expect{user.permitted_apos}.to_not raise_error
        expect(user.permitted_apos).to be_an Array
      end
    end
  end
  describe '#permitted_collections' do
    let(:user) { User.find_or_create_by_remoteuser 'test_user' }
    let(:many_groups) { (0..30).map { |num| "workgroup:workgroup_#{num}" } }
    context 'with large Solr query' do
      it 'does not raise an RSolr::Error::Http-413 Request Entity Too Large' do
        user.set_groups_to_impersonate many_groups
        expect{user.permitted_collections}.to_not raise_error
        expect(user.permitted_collections).to be_an Array
      end
    end
    it 'returns an array' do
      expect(user.permitted_collections).to eq [['None', '']]
    end
  end
end

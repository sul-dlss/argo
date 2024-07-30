# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'files/index' do
  let(:admin) { instance_double(Cocina::Models::FileAdministrative, shelve: true, sdrPreserve: true) }
  let(:preserved_url) { '/items/druid:rn653dy9317/files/dir/M1090_S15_B01_F07_0106.jp2/preserved?version=7' }
  let(:stacks_url) { 'https://stacks-test.stanford.edu/file/druid:rn653dy9317/dir/M1090_S15_B01_F07_0106.jp2' }
  let(:filename) { 'dir/M1090_S15_B01_F07_0106.jp2' }
  let(:user_version) { nil }

  before do
    @file = instance_double(Cocina::Models::File, administrative: admin, access:, filename:)
    @has_been_accessioned = true
    @version = '7'
    @user_version = user_version
    params[:id] = filename
    params[:item_id] = 'druid:rn653dy9317'
    render
  end

  context 'when download access is world' do
    let(:access) { instance_double(Cocina::Models::FileAccess, download: 'world') }

    it 'renders the partial content with links' do
      expect(rendered).to have_content 'Stacks'
      expect(rendered).to have_content 'Preservation'
      expect(rendered).to have_link stacks_url, href: stacks_url
      expect(rendered).to have_no_content '(not available for download)'
      expect(rendered).to have_link preserved_url, href: preserved_url
    end
  end

  context 'when download access is none' do
    let(:access) { instance_double(Cocina::Models::FileAccess, download: 'none') }

    it 'renders the partial content without links' do
      expect(rendered).to have_content 'Stacks'
      expect(rendered).to have_content 'Preservation'
      expect(rendered).to have_no_link stacks_url, href: stacks_url
      expect(rendered).to have_content '(not available for download)'
      expect(rendered).to have_link preserved_url, href: preserved_url
    end
  end

  context 'when a user version' do
    let(:access) { instance_double(Cocina::Models::FileAccess, download: 'world') }
    let(:user_version) { 2 }

    let(:stacks_url) { 'https://stacks-test.stanford.edu/v2/file/rn653dy9317/version/2/dir/M1090_S15_B01_F07_0106.jp2' }

    it 'renders the partial content with links' do
      expect(rendered).to have_content 'Stacks'
      expect(rendered).to have_content 'Preservation'
      expect(rendered).to have_link stacks_url, href: stacks_url
      expect(rendered).to have_no_content '(not available for download)'
      expect(rendered).to have_link preserved_url, href: preserved_url
    end
  end
end

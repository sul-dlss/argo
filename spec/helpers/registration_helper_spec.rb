# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RegistrationHelper do
  describe '#apo_list' do
    let(:perm_keys) { ['sunetid:user', 'workgroup:dlss:mock-group1', 'workgroup:dlss:mock-group2', 'workgroup:dlss:mock-group2/administrator'] }

    it 'runs the appropriate query for the given permission keys, filtering out groups ending with /administrator' do
      q = 'apo_register_permissions_ssim:"sunetid:user" OR '\
          'apo_register_permissions_ssim:"workgroup:dlss:mock-group1" OR '\
          'apo_register_permissions_ssim:"workgroup:dlss:mock-group2"'

      expect(SearchService).to receive(:query).with(
        q,
        defType: 'lucene',
        rows: 99_999,
        fl: 'id,tag_ssim,sw_display_title_tesim',
        fq: ['objectType_ssim:adminPolicy', '!tag_ssim:"Project : Hydrus"']
      ).and_return('response' => { 'docs' => [] })

      apo_list(perm_keys)
    end

    it 'sorts the results and formats them correctly' do
      result_rows = [
        { 'id' => 1, 'tag_ssim' => 'prefix : suffix', 'sw_display_title_tesim' => 'z' },
        { 'id' => 2, 'tag_ssim' => 'AdminPolicy : default', 'sw_display_title_tesim' => 'y' },
        { 'id' => 3, 'tag_ssim' => 'prefix : suffix2', 'sw_display_title_tesim' => 'x' }
      ]
      expect(SearchService).to receive(:query).and_return('response' => { 'docs' => result_rows })

      apos = apo_list(perm_keys)
      expect(apos).to eq [%w[y 2], %w[x 3], %w[z 1]]
    end
  end

  describe '#valid_content_types' do
    it 'returns the expected content types in the expected order' do
      expect(valid_content_types).to eq ['Book (ltr)', 'Book (rtl)', 'File', 'Image', 'Map', 'Media', '3D', 'Document', 'Geo', 'Webarchive-seed']
    end
  end

  it 'returns nothing when permission_keys is empty' do
    expect(SearchService).not_to receive(:query)
    expect(apo_list([])).to eq []
  end
end

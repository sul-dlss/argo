require 'spec_helper'

describe RegistrationHelper do
  describe '#apo_list' do
    let(:perm_keys) { ['sunetid:user', 'workgroup:dlss:mock-group1', 'workgroup:dlss:mock-group2'] }

    it 'runs the appropriate query for the given permission keys' do
      q = perm_keys.map { |key| %(apo_register_permissions_ssim:"#{key}") }.join(' OR ')

      expect(Dor::SearchService).to receive(:query).with(
        q,
        defType: 'lucene',
        rows: 99999,
        fl: 'id,tag_ssim,sw_display_title_tesim',
        fq: ['objectType_ssim:adminPolicy', '!tag_ssim:"Project : Hydrus"']
      ).and_return({ 'response' => { 'docs' => [] } })

      apo_list(perm_keys)
    end

    it 'sorts the results and formats them correctly' do
      result_rows = [
        {'id' => 1, 'tag_ssim' => 'prefix : suffix', 'sw_display_title_tesim' => 'z'},
        {'id' => 2, 'tag_ssim' => 'AdminPolicy : default', 'sw_display_title_tesim' => 'y'},
        {'id' => 3, 'tag_ssim' => 'prefix : suffix2', 'sw_display_title_tesim' => 'x'}
      ]
      expect(Dor::SearchService).to receive(:query).and_return({ 'response' => { 'docs' => result_rows }})

      apos = apo_list(perm_keys)
      expect(apos).to eq [['y', '2'], ['x', '3'], ['z', '1']]
    end
  end

  it 'returns nothing when permission_keys is empty' do
    expect(Dor::SearchService).to_not receive(:query)
    expect(apo_list([])).to eq []
  end
end

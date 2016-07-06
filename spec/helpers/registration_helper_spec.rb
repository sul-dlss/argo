require 'spec_helper'

describe RegistrationHelper do
  describe '#apo_list' do
    let(:perm_keys) { ['sunetid:user', 'workgroup:dlss:mock-group1', 'workgroup:dlss:mock-group2'] }

    it 'runs the appropriate query for the given permission keys' do
      q = 'objectType_ssim:adminPolicy AND !tag_ssim:"Project : Hydrus"'
      q += '(' + perm_keys.map { |key| %(apo_register_permissions_ssim:"#{key}") }.join(' OR ') + ')'

      expect(Dor::SearchService).to receive(:query).with(
        q,
        rows: 99999,
        fl: 'id,tag_ssim,dc_title_tesim'
      ).and_return(double(docs: []))

      apo_list(*perm_keys)
    end

    it 'sorts the results and formats them correctly' do
      result_rows = [
        {'id' => 1, 'tag_ssim' => 'prefix : suffix', 'dc_title_tesim' => 'z'},
        {'id' => 2, 'tag_ssim' => 'AdminPolicy : default', 'dc_title_tesim' => 'y'},
        {'id' => 3, 'tag_ssim' => 'prefix : suffix2', 'dc_title_tesim' => 'x'}
      ]
      expect(Dor::SearchService).to receive(:query).and_return(double(docs: result_rows))

      apos = apo_list(*perm_keys)
      expect(apos).to eq [['y', '2'], ['x', '3'], ['z', '1']]
    end
  end
end

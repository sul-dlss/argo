# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AdminPolicyOptions do
  let(:user) { instance_double(User, groups:) }

  describe '.for' do
    subject(:result) { described_class.for(user) }

    let(:result_rows) { [] }

    before do
      allow(SearchService).to receive(:query).and_return('response' => { 'docs' => result_rows })
    end

    context 'with groups' do
      let(:groups) do
        ['sunetid:user', 'workgroup:dlss:mock-group1', 'workgroup:dlss:mock-group2',
         'workgroup:dlss:mock-group2/administrator']
      end

      it 'runs the appropriate query for the given permission keys, filtering out groups ending with /administrator' do
        result
        expect(SearchService).to have_received(:query).with(
          'apo_register_permissions_ssim:"sunetid:user" OR ' \
          'apo_register_permissions_ssim:"workgroup:dlss:mock-group1" OR ' \
          'apo_register_permissions_ssim:"workgroup:dlss:mock-group2"',
          defType: 'lucene',
          rows: 99_999,
          fl: 'id,tag_ssim,display_title_ss',
          fq: ['objectType_ssim:adminPolicy', '!tag_ssim:"Project : Hydrus"', '!tag_ssim:"APO status : inactive"']
        )
      end

      context 'when rows are returned' do
        let(:result_rows) do
          [
            { 'id' => 1, 'tag_ssim' => 'prefix : suffix', 'display_title_ss' => 'z' },
            { 'id' => 2, 'tag_ssim' => 'AdminPolicy : default', 'display_title_ss' => '[y]' },
            { 'id' => 3, 'tag_ssim' => 'prefix : suffix2', 'display_title_ss' => 'x' }
          ]
        end

        it 'sorts the results and formats them correctly' do
          expect(result).to eq [%w[x 3], %w[[y] 2], %w[z 1]]
        end
      end
    end

    context 'with no groups' do
      let(:groups) { [] }

      it 'returns an empty array' do
        expect(SearchService).not_to receive(:query)
        expect(result).to eq []
      end
    end
  end
end

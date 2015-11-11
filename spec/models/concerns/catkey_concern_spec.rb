require 'spec_helper'

describe CatkeyConcern do
  let(:document) { SolrDocument.new(document_attributes) }
  describe '#catkey' do
    describe 'without one present' do
      let(:document_attributes) { { not_a_catkey: '8675309' } }
      it 'should return nil' do
        expect(document.catkey).to be_nil
      end
    end
    describe 'when a catkey is present' do
      let(:document_attributes) { { catkey_id_ssim: ['8675309'] } }
      it 'should return catkey value' do
        expect(document.catkey).to eq '8675309'
      end
    end
  end
end

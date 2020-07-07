# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'ContentBlocks', type: :request do
  let(:user) { create(:user) }
  let(:content_block) { create(:content_block) }

  before do
    sign_in user, groups: ['sdr:administrator-role']
  end

  describe 'GET /content_blocks' do
    before do
      create(:content_block)
      create(:content_block)
    end

    it 'displays the content blocks' do
      get content_blocks_path
      expect(response.body).to include 'Message alerts'
    end
  end

  describe 'POST /content_blocks' do
    let(:valid_params) do
      {
        content_block: {
          start_at: '2020-05-05', end_at: '2020-08-15', value: 'New text', ordinal: 1
        }
      }
    end

    it 'creates a new content block' do
      expect { post content_blocks_path, params: valid_params }.to change(ContentBlock, :count).by(1)
      expect(response).to redirect_to content_blocks_path
    end
  end

  describe 'PATCH /content_blocks/:id' do
    let(:valid_params) do
      {
        content_block: {
          start_at: '2020-05-05', end_at: '2020-08-15', value: 'New text', ordinal: 1
        }
      }
    end

    it 'redirects to the show page' do
      patch content_block_path(content_block.to_param), params: valid_params
      expect(response).to redirect_to content_blocks_path
      expect(content_block.reload.value).to eq 'New text'
    end
  end

  describe 'DELETE /content_blocks/:id' do
    let!(:content_block) { create(:content_block) }

    it 'removes the content block' do
      expect { delete content_block_path(content_block.to_param) }.to change(ContentBlock, :count).by(-1)
      expect(response).to redirect_to content_blocks_path
    end
  end
end

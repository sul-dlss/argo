# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Argo::Ability do
  subject(:ability) { described_class }

  describe 'can_manage_items?' do
    it 'matches a group that has rights' do
      expect(ability).to be_can_manage_items(['dor-administrator'])
    end
    it 'matches a group that has rights' do
      expect(ability).to be_can_manage_items(['sdr-administrator'])
    end
    it 'shouldnt match a group that doesnt have rights' do
      expect(ability).not_to be_can_manage_items(['dor-apo-metadata'])
    end
  end

  describe 'can_edit_desc_metadata?' do
    it 'matches a group that has rights' do
      expect(ability).to be_can_edit_desc_metadata(['dor-apo-metadata'])
    end
    it 'shouldnt match a group that doesnt have rights' do
      expect(ability).not_to be_can_edit_desc_metadata(['dor-viewer'])
    end
    it 'shouldnt match a group that doesnt have rights' do
      expect(ability).not_to be_can_edit_desc_metadata(['sdr-viewer'])
    end
  end

  describe 'can_view?' do
    it 'matches a group that has rights' do
      expect(ability).to be_can_view(['dor-viewer'])
    end
    it 'matches a group that has rights' do
      expect(ability).to be_can_view(['sdr-viewer'])
    end
    it 'shouldnt match a group that doesnt have rights' do
      expect(ability).not_to be_can_view(['dor-people'])
    end
  end
end

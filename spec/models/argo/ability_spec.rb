# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Argo::Ability do
  subject(:ability) { described_class }

  describe 'can_manage_item?' do
    it 'matches a group that has rights' do
      expect(ability).to be_can_manage_item(['dor-administrator'])
    end
    it 'matches a group that has rights' do
      expect(ability).to be_can_manage_item(['sdr-administrator'])
    end
    it 'shouldnt match a group that doesnt have rights' do
      expect(ability).not_to be_can_manage_item(['dor-apo-metadata'])
    end
  end

  describe 'can_manage_desc_metadata?' do
    it 'matches a group that has rights' do
      expect(ability).to be_can_manage_desc_metadata(['dor-apo-metadata'])
    end
    it 'shouldnt match a group that doesnt have rights' do
      expect(ability).not_to be_can_manage_desc_metadata(['dor-viewer'])
    end
    it 'shouldnt match a group that doesnt have rights' do
      expect(ability).not_to be_can_manage_desc_metadata(['sdr-viewer'])
    end
  end

  describe 'can_manage_content?' do
    it 'matches a group that has rights' do
      expect(ability).to be_can_manage_content(['dor-administrator'])
    end
    it 'matches a group that has rights' do
      expect(ability).to be_can_manage_content(['sdr-administrator'])
    end
    it 'shouldnt match a group that doesnt have rights' do
      expect(ability).not_to be_can_manage_content(['dor-apo-metadata'])
    end
  end

  describe 'can_manage_rights?' do
    it 'matches a group that has rights' do
      expect(ability).to be_can_manage_rights(['dor-administrator'])
    end
    it 'matches a group that has rights' do
      expect(ability).to be_can_manage_rights(['sdr-administrator'])
    end
    it 'shouldnt match a group that doesnt have rights' do
      expect(ability).not_to be_can_manage_rights(['dor-apo-metadata'])
    end
  end

  describe 'can_manage_embargo?' do
    it 'matches a group that has rights' do
      expect(ability).to be_can_manage_embargo(['dor-administrator'])
    end
    it 'matches a group that has rights' do
      expect(ability).to be_can_manage_embargo(['sdr-administrator'])
    end
    it 'shouldnt match a group that doesnt have rights' do
      expect(ability).not_to be_can_manage_embargo(['dor-apo-metadata'])
    end
  end

  describe 'can_view_content?' do
    it 'matches a group that has rights' do
      expect(ability).to be_can_view_content(['dor-viewer'])
    end
    it 'matches a group that has rights' do
      expect(ability).to be_can_view_content(['sdr-viewer'])
    end
    it 'shouldnt match a group that doesnt have rights' do
      expect(ability).not_to be_can_view_content(['dor-people'])
    end
  end

  describe 'can_view_metadata?' do
    it 'matches a group that has rights' do
      expect(ability).to be_can_view_metadata(['dor-viewer'])
    end
    it 'matches a group that has rights' do
      expect(ability).to be_can_view_metadata(['sdr-viewer'])
    end
    it 'shouldnt match a group that doesnt have rights' do
      expect(ability).not_to be_can_view_metadata(['dor-people'])
    end
  end
end

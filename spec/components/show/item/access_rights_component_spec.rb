# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Show::Item::AccessRightsComponent, type: :component do
  let(:component) { described_class.new(change_set: change_set, state_service: state_service) }
  let(:change_set) { ItemChangeSet.new(item) }
  let(:rendered) { render_inline(component) }
  let(:allows_modification) { true }
  let(:state_service) { instance_double(StateService, allows_modification?: allows_modification) }

  context 'with view location' do
    let(:item) { build(:item, view_access: 'location-based', download_access: 'none', access_location: 'm&m') }

    it 'shows the description' do
      expect(rendered.to_html).to include 'View: Location: m&amp;m, Download: None'
    end
  end

  context 'with download location' do
    let(:item) { build(:item, view_access: 'world', download_access: 'location-based', access_location: 'm&m') }

    it 'shows the description' do
      expect(rendered.to_html).to include 'View: World, Download: Location: m&amp;m'
    end
  end
end

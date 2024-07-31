# frozen_string_literal: true

require 'rails_helper'

RSpec.describe VersionMilestonesComponent, type: :component do
  subject(:instance) do
    described_class.new(version: 2,
                        milestones_presenter:,
                        user_versions_presenter:)
  end

  let(:milestones_presenter) do
    instance_double(MilestonesPresenter,
                    steps_for: steps,
                    version_title: '2 (2.0.0) Add collection, set rights to citations',
                    current_version:,
                    druid: 'druid:mk420bs7601')
  end
  let(:user_versions_presenter) { instance_double(UserVersionsPresenter, user_version_for: user_version, user_version: 1, head_user_version: 3) }
  let(:user_version) { nil }
  let(:current_version) { 2 }

  let(:steps) do
    { 'accessioned' => { display: 'foo',
                         time: DateTime.parse('2020-05-12') } }
  end

  context 'when the accessioned milestone has display' do
    it 'renders something useful' do
      render_inline(instance)
      expect(page).to have_text '2 (2.0.0) Add collection, set rights to citations'
      expect(page).to have_css 'tr.version2', count: 2
      expect(milestones_presenter).to have_received(:steps_for).with(2)
      expect(milestones_presenter).to have_received(:version_title).with(2)
      expect(user_versions_presenter).to have_received(:user_version_for).with(2)
    end
  end

  context "when the accessioned milestone doesn't have display" do
    let(:steps) do
      { 'accessioned' => {} }
    end

    it 'renders something useful' do
      render_inline(instance)
      expect(page).to have_text '2 (2.0.0) Add collection, set rights to citations'
      expect(page).to have_css 'tr.version2', count: 2
    end
  end

  context 'when the accessioned milestone has user version' do
    let(:user_version) { 2 }
    let(:current_version) { 3 }

    it 'renders link to user version' do
      render_inline(instance)
      expect(page).to have_link 'Public version 2', href: '/items/druid:mk420bs7601/user_versions/2'
    end
  end

  context 'when the accessioned milestone has user version and that is the current version being displayed' do
    let(:user_version) { 1 }
    let(:current_version) { 3 }

    it 'renders the user version but not as a link' do
      render_inline(instance)
      expect(page).to have_text 'Public version 1'
      expect(page).to have_no_link 'Public version 1', href: '/items/druid:mk420bs7601/user_versions/1'
    end
  end

  context 'when the accessioned milestone has user version that is the current object version' do
    let(:user_version) { 2 }

    it 'renders the user version but not as a link' do
      render_inline(instance)
      expect(page).to have_text 'Public version 2'
      expect(page).to have_no_link 'Public version 2', href: '/items/druid:mk420bs7601/user_versions/2'
    end
  end

  context 'when the accessioned milestone has user version that is head version' do
    let(:user_version) { 3 }

    it 'renders the user version as a link to document path' do
      render_inline(instance)
      expect(page).to have_text 'Public version 3'
      expect(page).to have_no_link 'Public version 3', href: '/items/druid:mk420bs7601'
    end
  end
end

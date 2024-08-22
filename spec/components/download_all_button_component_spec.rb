# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DownloadAllButtonComponent, type: :component do
  include Rails.application.routes.url_helpers
  subject { page }

  let(:cocina) { build(:dro) }
  let(:document) { instance_double(SolrDocument, preservation_size: 0, id: druid) }
  let(:presenter) { instance_double(ArgoShowPresenter, user_version_view?: user_version.present?, user_version_view: user_version, cocina:, version_view?: version_view) }
  let(:druid) { 'druid:tx739ch3649' }
  let(:user_version) { nil }
  let(:version_view) { false }
  let(:component) { described_class.new(document:, presenter:) }

  context 'when accessioned' do
    before do
      allow(WorkflowService).to receive(:accessioned?).and_return(true)
      render_inline(component)
    end

    it { is_expected.to have_link 'Download all files', href: download_item_files_path(document) }
    it { is_expected.to have_css 'a[onclick="event.stopPropagation()"]' }

    context 'with a large file' do
      let(:document) { instance_double(SolrDocument, preservation_size: 1_000_000_000) }

      it { is_expected.to have_css 'a[data-turbo-confirm="This will be a large download. Are you sure?"]' }
    end
  end

  context 'when not accessioned' do
    before do
      allow(WorkflowService).to receive(:accessioned?).and_return(false)
      render_inline(component)
    end

    it { is_expected.to have_no_link 'Download all files', href: download_item_files_path(document) }
  end

  context 'when a user version' do
    let(:user_version) { 2 }

    before do
      allow(WorkflowService).to receive(:accessioned?).and_return(true)
      render_inline(component)
    end

    it { is_expected.to have_link 'Download all files', href: download_item_public_version_files_path(druid, user_version) }
  end

  context 'when a version' do
    let(:version_view) { true }

    before do
      allow(WorkflowService).to receive(:accessioned?).and_return(true)
      render_inline(component)
    end

    it { is_expected.to have_no_link 'Download all files' }
  end
end

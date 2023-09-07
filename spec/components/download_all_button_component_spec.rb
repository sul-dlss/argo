# frozen_string_literal: true

require "rails_helper"

RSpec.describe DownloadAllButtonComponent, type: :component do
  include Rails.application.routes.url_helpers
  subject { page }

  let(:cocina) { build(:dro) }
  let(:document) { instance_double(SolrDocument, preservation_size: 0) }
  let(:component) { described_class.new(document:, cocina:) }
  let(:state_service) { instance_double(StateService) }

  before do
    allow(StateService).to receive(:new).and_return(state_service)
  end

  context "when accessioned" do
    before do
      allow(state_service).to receive(:accessioned?).and_return(true)
      render_inline(component)
    end

    it { is_expected.to have_link "Download all files", href: download_item_files_path(document) }
    it { is_expected.to have_selector 'a[onclick="event.stopPropagation()"]' }

    context "with a large file" do
      let(:document) { instance_double(SolrDocument, preservation_size: 1_000_000_000) }

      it { is_expected.to have_selector 'a[data-turbo-confirm="This will be a large download. Are you sure?"]' }
    end
  end

  context "when not accessioned" do
    before do
      allow(state_service).to receive(:accessioned?).and_return(false)
      render_inline(component)
    end

    it { is_expected.not_to have_link "Download all files", href: download_item_files_path(document) }
  end
end

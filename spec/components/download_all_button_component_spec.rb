# frozen_string_literal: true

require "rails_helper"

RSpec.describe DownloadAllButtonComponent, type: :component do
  include Rails.application.routes.url_helpers
  subject { page }

  let(:document) { instance_double(SolrDocument, preservation_size: 0) }
  let(:component) { described_class.new(document:) }

  before do
    render_inline(component)
  end

  it { is_expected.to have_link "Download all files", href: download_item_files_path(document) }
  it { is_expected.to have_selector 'a[onclick="event.stopPropagation()"]' }

  context "with a large file" do
    let(:document) { instance_double(SolrDocument, preservation_size: 1_000_000_000) }

    it { is_expected.to have_selector 'a[data-turbo-confirm="This will be a large download. Are you sure?"]' }
  end
end

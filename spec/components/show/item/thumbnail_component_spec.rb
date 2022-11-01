# frozen_string_literal: true

require "rails_helper"

RSpec.describe Show::Item::ThumbnailComponent, type: :component do
  let(:component) { described_class.new(document:) }
  let(:rendered) { render_inline(component) }

  let(:document) do
    SolrDocument.new("id" => "druid:kv840xx0000",
      SolrDocument::FIELD_TITLE => title)
  end

  context "without a thumbnail_url and a long title" do
    let(:title) do
      "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Proin dolor mauris, " \
        "tincidunt ut elementum sollicitudin, luctus sit amet quam. Interdum et " \
        "malesuada fames ac ante ipsum primis in faucibus.  Proin maximus, urna id " \
        "gravida sodales, dui ex ullamcorper ante, vestibulum consectetur odio arcu " \
        "mattis dolor. "
    end

    it "truncates the title" do
      expect(rendered.to_html).to include "gravida sodales, dui ex…"
    end
  end
end

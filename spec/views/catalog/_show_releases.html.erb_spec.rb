# frozen_string_literal: true

require "rails_helper"

RSpec.describe "catalog/_show_releases" do
  let(:release_tags) do
    [
      Cocina::Models::ReleaseTag.new(to: "Searchworks", what: "self", date: "2016-09-12T20:00Z", who: "pjreed", release: false),
      Cocina::Models::ReleaseTag.new(to: "Searchworks", what: "self", date: "2016-09-13T20:00Z", who: "pjreed", release: true)
    ]
  end

  before do
    allow(view).to receive(:release_tags).and_return(release_tags)
  end

  it "displays a table of release tags" do
    render
    expect(rendered).to have_css "table.table"
    expect(rendered).to have_css "tbody td:nth-child(1)", text: "true"
    expect(rendered).to have_css "tbody td:nth-child(2)", text: "self", count: 2
    expect(rendered).to have_css "tbody td:nth-child(3)", text: "Searchworks", count: 2
    expect(rendered).to have_css "tbody td:nth-child(4)", text: "pjreed", count: 2
    expect(rendered).to have_css "tbody td:nth-child(5)", text: "2016-09-13T20:00:00+00:00"
  end
end

# frozen_string_literal: true

require "rails_helper"

RSpec.describe ManageRelease::FormComponent, type: :component do
  subject(:component) { described_class.new(bulk_action:, document:) }

  let(:document) { SolrDocument.new(id: "druid:123", objectType_ssim: "collection") }
  let(:bulk_action) { BulkAction.new }
  let(:rendered) { render_inline(component) }

  before do
    allow(controller).to receive_messages(
      current_user: build(:user)
    )
  end

  it "renders the form" do
    expect(rendered.to_html).to include(
      "Manage release to discovery applications for collection druid:123"
    )

    expect(rendered.css("button").inner_html).to eq "Submit"
  end
end

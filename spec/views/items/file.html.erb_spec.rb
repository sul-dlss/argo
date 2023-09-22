# frozen_string_literal: true

require "rails_helper"

RSpec.describe "items/file" do
  it "renders the template" do
    stub_template "items/_file.html.erb" => "stubbed_file"
    render
    expect(rendered).to have_css ".modal-header h1.modal-title", text: "Files"
    expect(rendered).to have_css ".modal-body", text: "stubbed_file"
  end
end

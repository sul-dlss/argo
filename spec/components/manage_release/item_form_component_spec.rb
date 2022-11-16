# frozen_string_literal: true

require "rails_helper"

RSpec.describe ManageRelease::ItemFormComponent, type: :component do
  subject(:component) { described_class.new(form:, current_user: build(:user)) }

  let(:form) { ActionView::Helpers::FormBuilder.new(nil, nil, controller.view_context, {}) }
  let(:rendered) { render_inline(component) }

  it "renders the options" do
    expect(rendered.css("label").to_html).to include(
      "Release this object*",
      "Do not release this object*"
    )

    expect(rendered.css("select option").to_html).to include(
      "Searchworks",
      "Earthworks"
    )
  end
end

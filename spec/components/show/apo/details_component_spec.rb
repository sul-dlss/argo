# frozen_string_literal: true

require "rails_helper"

RSpec.describe Show::Apo::DetailsComponent, type: :component do
  let(:component) { described_class.new(presenter:) }
  let(:presenter) { instance_double(ArgoShowPresenter, document: doc, cocina:, state_service:) }
  let(:cocina) { build(:admin_policy) }
  let(:rendered) { render_inline(component) }
  let(:allows_modification) { true }
  let(:state_service) { instance_double(StateService, allows_modification?: allows_modification) }
  let(:doc) do
    SolrDocument.new("id" => "druid:kv840xx0000",
      SolrDocument::FIELD_REGISTERED_DATE => ["2012-04-05T01:00:04.148Z"],
      SolrDocument::FIELD_OBJECT_TYPE => object_type)
  end
  let(:object_type) { "adminPolicy" }

  context "when allows_modification is true" do
    it "renders the appropriate buttons" do
      expect(rendered.css("a[aria-label='Edit tags']")).to be_present
    end
  end
end

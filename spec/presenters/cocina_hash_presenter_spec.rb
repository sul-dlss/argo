# frozen_string_literal: true

require "rails_helper"

RSpec.describe CocinaHashPresenter do
  subject(:presenter) { described_class.new(cocina_object:, without_metadata:) }

  let(:without_metadata) { false }

  describe "#render" do
    subject(:rendered) { presenter.render }

    context "without metadata" do
      let(:cocina_object) do
        build(:admin_policy_with_metadata)
      end
      let(:without_metadata) { true }

      it "returns the object without a lock" do
        expect(rendered).not_to have_key(:lock)
      end
    end

    context "when cocina object has descriptive metadata" do
      let(:cocina_object) do
        build(:collection_with_metadata)
      end

      # NOTE: You might not see an empty e.g. `structuredValue` array above, but it's there in the instance
      it "removes empty descriptive elements" do
        expect(rendered).to eq(cocinaVersion: Cocina::Models::VERSION,
          lock: cocina_object.lock,
          type: "https://cocina.sul.stanford.edu/models/collection",
          externalIdentifier: cocina_object.externalIdentifier,
          label: cocina_object.label,
          version: 1,
          access: {
            view: "dark"
          },
          administrative: {
            hasAdminPolicy: "druid:hv992ry2431",
            releaseTags: []
          },
          identification: {
            catalogLinks: []
          },
          description: {
            title: [
              {value: "factory collection title"}
            ],
            purl: cocina_object.description.purl
          })
      end
    end
  end
end

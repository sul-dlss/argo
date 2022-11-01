# frozen_string_literal: true

require "rails_helper"

RSpec.describe ShowEmbargoComponent, type: :component do
  let(:component) { described_class.new(presenter:) }
  let(:rendered) { render_inline(component) }
  let(:presenter) { instance_double(ArgoShowPresenter, document:, state_service:) }
  let(:state_service) { instance_double(StateService, allows_modification?: allows_modification) }

  context "embargoed with release date" do
    let(:document) do
      SolrDocument.new(
        :id => "druid:kv840xx0000",
        SolrDocument::FIELD_EMBARGO_STATUS => ["embargoed"],
        SolrDocument::FIELD_EMBARGO_RELEASE_DATE => ["24/02/2259"]
      )
    end

    context "with unlocked object" do
      let(:allows_modification) { true }

      it "displays release date and edit icon" do
        expect(rendered.to_html).to include "Embargoed until February 24, 2259"
        link = rendered.css("a[href='/items/druid:kv840xx0000/embargo/edit']")
        expect(link.attr("aria-label").value).to eq "Manage embargo"
      end
    end

    context "with locked object" do
      let(:allows_modification) { false }

      it "displays release date but not edit link" do
        expect(rendered.to_html).to include "Embargoed until February 24, 2259"
        link = rendered.css("a[href='/items/druid:kv840xx0000/embargo/edit']")
        expect(link).not_to be_present
      end
    end
  end

  context "embargoed without release date" do
    let(:allows_modification) { true }
    let(:document) do
      SolrDocument.new(
        :id => 1,
        SolrDocument::FIELD_EMBARGO_STATUS => ["embargoed"]
      )
    end

    it "does not render anything" do
      expect(rendered.to_html).to eq ""
    end
  end

  context "not embargoed with release date" do
    let(:allows_modification) { true }
    let(:document) do
      SolrDocument.new(
        :id => 1,
        SolrDocument::FIELD_EMBARGO_STATUS => ["strange occurrence"],
        SolrDocument::FIELD_EMBARGO_RELEASE_DATE => ["24/02/2259"]
      )
    end

    it "does not render anything" do
      expect(rendered.to_html).to eq ""
    end
  end
end

# frozen_string_literal: true

require "rails_helper"

RSpec.describe Show::Apo::OverviewComponent, type: :component do
  let(:component) { described_class.new(presenter:) }
  let(:presenter) { instance_double(ArgoShowPresenter, document: doc, cocina:, state_service:) }
  let(:cocina) do
    build(:admin_policy, registration_workflow: %w[registrationWF goobiWF])
  end
  let(:rendered) { render_inline(component) }
  let(:allows_modification) { true }
  let(:state_service) { instance_double(StateService, allows_modification?: allows_modification) }

  let(:doc) do
    SolrDocument.new("id" => "druid:kv840xx0000",
      SolrDocument::FIELD_OBJECT_TYPE => "adminPolicy")
  end

  context "when showing an APO including registration workflows" do
    it "renders the appropriate fields" do
      expect(rendered.to_html).to include "DRUID"
      expect(rendered.to_html).to include "Status"
      expect(rendered.to_html).to include "Access rights"
      expect(rendered.to_html).to include "Registration workflow"
      expect(rendered.to_html).to include "registrationWF, goobiWF"
    end
  end

  context "when the APO has no registration workflow" do
    let(:cocina) do
      build(:admin_policy)
    end

    it 'renders "None"' do
      expect(rendered.css("tr:last-child").to_html).to include "None"
    end
  end
end

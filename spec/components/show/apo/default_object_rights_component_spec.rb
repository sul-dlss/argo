# frozen_string_literal: true

require "rails_helper"

RSpec.describe Show::Apo::DefaultObjectRightsComponent, type: :component do
  let(:component) { described_class.new(presenter:) }
  let(:presenter) { instance_double(ArgoShowPresenter, document: doc, cocina:) }
  let(:cocina) do
    build(:admin_policy, use_statement: "Use and reproduction statement.",
      copyright: "This is the copyright.",
      license: "https://www.gnu.org/licenses/agpl.txt")
  end
  let(:doc) do
    SolrDocument.new("id" => "druid:bb663yf7144",
      SolrDocument::FIELD_OBJECT_TYPE => "adminPolicy",
      SolrDocument::FIELD_DEFAULT_ACCESS_RIGHTS => "location - spec")
  end
  let(:rendered) { render_inline(component) }

  it "shows the copyright, license, use statement and default access rights" do
    # these come from the cocina model:
    expect(rendered.to_html).to include "Use and reproduction statement."
    expect(rendered.to_html).to include "This is the copyright."
    expect(rendered.to_html).to include "https://www.gnu.org/licenses/agpl.txt"

    # this comes from the solr document:
    expect(rendered.to_html).to include "location - spec"
  end
end

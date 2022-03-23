# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Show::Apo::DefaultObjectRightsComponent, type: :component do
  let(:component) { described_class.new(presenter: presenter) }
  let(:presenter) { instance_double(ArgoShowPresenter, document: doc, item: item) }
  let(:item) do
    build(:admin_policy).tap do |apo|
      apo.access_template.use_statement = 'Use and reproduction statement.'
      apo.access_template.copyright = 'This is the copyright.'
      apo.access_template.license = 'A license goes here.'
    end
  end

  let(:doc) do
    SolrDocument.new('id' => 'druid:bb663yf7144',
                     SolrDocument::FIELD_OBJECT_TYPE => 'adminPolicy',
                     SolrDocument::FIELD_DEFAULT_ACCESS_RIGHTS => 'location - spec')
  end
  let(:rendered) { render_inline(component) }

  it 'shows the copyright, license, use statement and default access rights' do
    # these come from the cocina model:
    expect(rendered.to_html).to include 'Use and reproduction statement.'
    expect(rendered.to_html).to include 'This is the copyright.'
    expect(rendered.to_html).to include 'A license goes here.'

    # this comes from the solr document:
    expect(rendered.to_html).to include 'location - spec'
  end
end

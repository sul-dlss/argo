# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Show::Apo::DefaultObjectRightsComponent, type: :component do
  let(:component) { described_class.new(presenter: presenter) }
  let(:presenter) { instance_double(ArgoShowPresenter, document: doc, cocina: cocina) }
  let(:cocina) do
    Cocina::Models::AdminPolicy.new(externalIdentifier: 'druid:bb663yf7144',
                                    type: Cocina::Models::Vocab.admin_policy,
                                    label: 'An APO',
                                    version: 1,
                                    administrative: {
                                      hasAdminPolicy: 'druid:hv992ry2431',
                                      hasAgreement: 'druid:hp308wm0436',
                                      defaultAccess: {
                                        access: 'location-based',
                                        download: 'location-based',
                                        readLocation: 'spec',
                                        useAndReproductionStatement: 'Use and reproduction statement.',
                                        copyright: 'This is the copyright.',
                                        license: 'A license goes here.'
                                      }
                                    })
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

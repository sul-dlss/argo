# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Show::Apo::OverviewComponent, type: :component do
  let(:component) { described_class.new(presenter: presenter) }
  let(:presenter) { instance_double(ArgoShowPresenter, document: doc, cocina: cocina, state_service: state_service) }
  let(:cocina) do
    Cocina::Models::AdminPolicy.new(externalIdentifier: 'druid:bc234fg5678',
                                    type: Cocina::Models::Vocab.admin_policy,
                                    label: '',
                                    version: 1,
                                    administrative: {
                                      hasAdminPolicy: 'druid:hv992ry2431',
                                      hasAgreement: 'druid:hp308wm0436',
                                      defaultAccess: { access: 'world', download: 'world' },
                                      registrationWorkflow: %w[registrationWF goobiWF]
                                    })
  end
  let(:rendered) { render_inline(component) }
  let(:allows_modification) { true }
  let(:state_service) { instance_double(StateService, allows_modification?: allows_modification) }

  let(:doc) do
    SolrDocument.new('id' => 'druid:kv840xx0000',
                     SolrDocument::FIELD_OBJECT_TYPE => 'adminPolicy')
  end

  context 'when showing an APO including registration workflows' do
    it 'renders the appropriate fields' do
      expect(rendered.to_html).to include 'DRUID'
      expect(rendered.to_html).to include 'Status'
      expect(rendered.to_html).to include 'Access rights'
      expect(rendered.to_html).to include 'Registration workflow'
      expect(rendered.to_html).to include 'registrationWF, goobiWF'
    end
  end

  context 'when the APO has no registration workflow' do
    let(:cocina) do
      Cocina::Models::AdminPolicy.new(externalIdentifier: 'druid:bc234fg5678',
                                      type: Cocina::Models::Vocab.admin_policy,
                                      label: '',
                                      version: 1,
                                      administrative: {
                                        hasAdminPolicy: 'druid:hv992ry2431',
                                        hasAgreement: 'druid:hp308wm0436',
                                        defaultAccess: { access: 'world', download: 'world' },
                                        registrationWorkflow: []
                                      })
    end

    it 'renders "None"' do
      expect(rendered.css('tr:last-child').to_html).to include 'None'
    end
  end
end

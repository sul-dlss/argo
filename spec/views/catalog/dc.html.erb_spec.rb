# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'catalog/dc.html.erb' do
  let(:object_client) { instance_double(Dor::Services::Client::Object, metadata: metadata) }
  let(:metadata) { instance_double(Dor::Services::Client::Metadata, dublin_core: xml) }
  let(:xml) do
    <<~XML
      <oai_dc:dc xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:oai_dc="http://www.openarchives.org/OAI/2.0/oai_dc/">
        <dc:title>Kurdish Democratic Party</dc:title>
      </oai_dc:dc>
    XML
  end

  before do
    @obj = instance_double(Dor::Item, pid: 'druid:123abc', label: 'My digital object')
    # TODO: Move service call out of the view and into the controller
    allow(Dor::Services::Client).to receive(:object).and_return(object_client)
  end

  it 'renders the modal' do
    render
    expect(rendered)
      .to have_css '.modal-header h3.modal-title', text: 'Dublin Core (derived from MODS)'
    expect(rendered).to have_css '.modal-body', text: 'Kurdish Democratic Party'
  end
end

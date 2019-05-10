# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'items/_collection_ui.html.erb' do
  let(:collection) do
    double('collection', label: 'Dogs are better than catz', pid: 'druid:abc123')
  end
  let(:object) do
    double('object', collections: [collection, collection], pid: 'druid:abc123')
  end
  let(:current_user) do
    mock_user(permitted_collections: ['Catz are our legacy'])
  end

  it 'renders the partial content' do
    allow(collection).to receive_message_chain(:descMetadata, :title_info).and_return(['But catz are nice too', 'A different node that will not show'])
    assign(:object, object)
    expect(view).to receive(:current_user).and_return(current_user)
    render
    expect(rendered).to have_css '.panel .panel-heading h3.panel-title', text: 'Remove existing collections'
    expect(rendered).to have_css '.panel-body .list-group li.list-group-item', text: 'But catz are nice too' # the descMetadata title_info should display
    expect(rendered).not_to have_css '.panel-body .list-group li.list-group-item', text: 'Dogs are better than catz' # the fedora label should *not* be there
    expect(rendered).to have_css '.panel-body .list-group li.list-group-item a span.glyphicon.glyphicon-remove.text-danger'
    expect(rendered).to have_css '.panel .panel-heading h3.panel-title', text: 'Add a collection'
    expect(rendered).to have_css '.panel-body form .form-group select.form-control option', text: 'Catz are our legacy'
    expect(rendered).to have_css '.panel-body form button.btn.btn-primary', text: 'Add Collection'
  end
end

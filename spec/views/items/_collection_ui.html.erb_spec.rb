# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'items/_collection_ui.html.erb' do
  let(:collection_list) do
    [
      instance_double(Cocina::Models::Collection, label: 'But catz are nice too', externalIdentifier: 'druid:abc123')
    ]
  end
  let(:current_user) do
    mock_user(permitted_collections: ['Catz are our legacy'])
  end

  before do
    @cocina = instance_double(Cocina::Models::DRO, externalIdentifier: 'druid:abc123')
    assign(:collection_list, collection_list)
    allow(view).to receive(:current_user).and_return(current_user)
  end

  it 'renders the partial content' do
    render 'items/collection_ui', response_message: nil
    expect(rendered).to have_css '.panel .panel-heading h3.panel-title', text: 'Remove existing collections'
    expect(rendered).to have_css '.panel-body .list-group li.list-group-item', text: 'But catz are nice too' # the descMetadata title_info should display
    expect(rendered).to have_css '.panel-body .list-group li.list-group-item a span.icon-remove-sign.text-danger'
    expect(rendered).to have_css '.panel .panel-heading h3.panel-title', text: 'Add a collection'
    expect(rendered).to have_css '.panel-body form select option', text: 'Catz are our legacy'
    expect(rendered).to have_css '.panel-body form button.btn.btn-primary', text: 'Add Collection'
  end
end

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'items/_rights.html.erb' do
  before do
    @cocina = instance_double(Cocina::Models::DRO, externalIdentifier: 'druid:abc123')
    @form = instance_double(AccessForm, model_name: instance_double(ActiveModel::Name, param_key: 'pid'), rights_list: Constants::REGISTRATION_RIGHTS_OPTIONS)
    render
  end

  it 'renders the partial content' do
    expect(rendered)
      .to have_css 'select option', text: 'World'
    expect(rendered)
      .to have_css 'select option', text: 'Dark (Preserve Only)'
    expect(rendered)
      .to have_css 'select option', text: 'Stanford'
    expect(rendered)
      .to have_css 'select option', text: 'Citation Only'
    expect(rendered).to have_css 'button.btn.btn-primary', text: 'Update'
  end
end

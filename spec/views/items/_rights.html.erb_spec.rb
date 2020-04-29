# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'items/_rights.html.erb' do
  before do
    @object = instance_double(Dor::Item, pid: 'druid:abc123')
    @form = instance_double(AccessForm, model_name: instance_double(ActiveModel::Name, param_key: 'pid'))
    render
  end

  it 'renders the partial content' do
    expect(rendered)
      .to have_css '.form-group select.form-control option', text: 'World'
    expect(rendered)
      .to have_css '.form-group select.form-control option', text: 'Dark (Preserve Only)'
    expect(rendered)
      .to have_css '.form-group select.form-control option', text: 'Stanford'
    expect(rendered)
      .to have_css '.form-group select.form-control option', text: 'Citation Only'
    expect(rendered).to have_css 'button.btn.btn-primary', text: 'Update'
  end
end

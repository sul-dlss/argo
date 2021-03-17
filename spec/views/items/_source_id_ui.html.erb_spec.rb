# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'items/_source_id_ui.html.erb' do
  let(:identification) do
    instance_double(Cocina::Models::Identification, sourceId: 'source id')
  end

  before do
    @cocina = instance_double(Cocina::Models::DRO, externalIdentifier: 'druid:987', identification: identification)
  end

  it 'renders the partial content' do
    render
    expect(rendered)
      .to have_css 'form .form-group input.form-control[value="source id"]'
    expect(rendered).to have_css 'p.help-block'
    expect(rendered).to have_css 'button.btn.btn-primary', text: 'Update'
  end
end

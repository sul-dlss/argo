# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'items/_source_id_ui' do
  let(:identification) do
    instance_double(Cocina::Models::Identification, sourceId: 'source id')
  end

  before do
    @cocina = instance_double(Cocina::Models::DRO, externalIdentifier: 'druid:987', identification: identification)
  end

  it 'renders the partial content' do
    render
    expect(rendered)
      .to have_css 'form input.form-control[value="source id"]'
    expect(rendered).to have_css 'p.form-text'
    expect(rendered).to have_css 'button.btn.btn-primary', text: 'Update'
  end
end

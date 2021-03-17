# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'items/_set_governing_apo_ui.html.erb' do
  let(:administrative) { instance_double(Cocina::Models::Administrative, hasAdminPolicy: 'druid:123') }
  let(:groups) { ['dlss-developers'] }
  let(:current_user) { double(User, groups: groups) }
  let(:apo_list) { [['APO 1', 'druid:123'], ['APO 2', 'druid:234']] }

  before do
    @cocina = instance_double(Cocina::Models::DRO, externalIdentifier: 'druid:987', administrative: administrative)

    allow(view).to receive(:current_user).and_return(current_user)
    allow(view).to receive(:apo_list).with(groups).and_return(apo_list)
    render
  end

  it 'renders the partial content' do
    expect(rendered).to have_css 'select[name="new_apo_id"] option[value="druid:123"][selected="selected"]'
    expect(rendered).to have_css 'select[name="new_apo_id"] option[value="druid:234"]'
    expect(rendered).to have_css 'button.btn-primary', text: 'Update'
    expect(rendered).to have_css 'form[action="/items/druid:987/set_governing_apo"]'
  end
end

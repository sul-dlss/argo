# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'items/_set_governing_apo_ui' do
  let(:groups) { ['dlss-developers'] }
  let(:current_user) { instance_double(User, groups:) }
  let(:apo_list) { [['APO 1', 'druid:tv123km1122'], ['APO 2', 'druid:234']] }

  before do
    @cocina = build(:dro, id: 'druid:bh987zz0000', admin_policy_id: 'druid:tv123km1122')

    allow(view).to receive(:current_user).and_return(current_user)
    allow(view).to receive(:apo_list).with(groups).and_return(apo_list)
    render
  end

  it 'renders the partial content' do
    expect(rendered).to have_css 'select[name="new_apo_id"] option[value="druid:tv123km1122"][selected="selected"]'
    expect(rendered).to have_css 'select[name="new_apo_id"] option[value="druid:234"]'
    expect(rendered).to have_css 'button.btn-primary', text: 'Update'
    expect(rendered).to have_css 'form[action="/items/druid:bh987zz0000/set_governing_apo"]'
  end
end

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'items/_set_governing_apo_ui.html.erb' do
  let(:object) { double(Dor::Item, pid: 'druid:987', admin_policy_object: cur_apo) }
  let(:groups) { ['dlss-developers'] }
  let(:current_user) { double(User, groups: groups) }
  let(:apo_list) { [['APO 1', 'druid:123'], ['APO 2', 'druid:234']] }

  before do
    assign(:object, object)
    allow(view).to receive(:current_user).and_return(current_user)
    allow(view).to receive(:apo_list).with(groups).and_return(apo_list)
    render
  end

  context 'current APO is not nil' do
    let(:cur_apo) { double(Dor::AdminPolicyObject, pid: 'druid:123') }

    it 'renders the partial content' do
      expect(rendered).to have_css 'select[name="new_apo_id"] option[value="druid:123"][selected="selected"]'
      expect(rendered).to have_css 'select[name="new_apo_id"] option[value="druid:234"]'
      expect(rendered).to have_css 'button.btn-primary', text: 'Update'
      expect(rendered).to have_css 'form[action="/items/druid:987/set_governing_apo"]'
    end
  end

  context 'current APO is nil' do
    let(:cur_apo) { nil }

    it 'renders the partial content' do
      expect(rendered).not_to have_css 'select[name="new_apo_id"] option[selected="selected"]'
      expect(rendered).to have_css 'select[name="new_apo_id"] option[value="druid:123"]'
      expect(rendered).to have_css 'select[name="new_apo_id"] option[value="druid:234"]'
      expect(rendered).to have_css 'button.btn-primary', text: 'Update'
      expect(rendered).to have_css 'form[action="/items/druid:987/set_governing_apo"]'
    end
  end
end

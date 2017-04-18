require 'spec_helper'

RSpec.describe 'bulk_actions/_form.html.erb' do
  let(:user_groups) { ['dlss-developers', 'top-secret-clearance'] }
  let(:apo_list) { [['APO 1', 'druid:123'], ['APO 2', 'druid:234']] }

  before do
    @bulk_action = assign(:bulk_actions, create(:bulk_action))
    allow(view).to receive(:current_user).and_return(double(sunetid: 'esnowden', groups: user_groups))
    allow(view).to receive(:apo_list).with(user_groups).and_return(apo_list)

    render
  end

  it 'form by default has action_type selected' do
    expect(rendered)
      .to have_css 'input[type="radio"][value="DescmetadataDownloadJob"][checked="checked"]'
  end

  describe 'common form fields' do
    it 'has proper form input values' do
      expect(rendered).to have_css 'textarea[name="bulk_action[pids]"]'
      expect(rendered).to have_css 'textarea[name="bulk_action[description]"]'
    end
  end

  describe 'Release Object Job form' do
    it 'has proper form input values' do
      expect(rendered).to have_css 'input[type="radio"][value="ReleaseObjectJob"]'
      expect(rendered).to have_css 'input[type="radio"][value="true"][checked="checked"][name="bulk_action[manage_release][tag]"]'
      expect(rendered).to have_css 'input[type="radio"][value="false"][name="bulk_action[manage_release][tag]"]'
      expect(rendered).to have_css 'select[name="bulk_action[manage_release][to]"]'
      expect(rendered).to have_css 'option[value="Searchworks"]'
      expect(rendered).to have_css 'input[value="self"][type="hidden"][name="bulk_action[manage_release][what]"]', visible: false
      expect(rendered).to have_css 'input[value="esnowden"][type="hidden"][name="bulk_action[manage_release][who]"]', visible: false
    end
  end

  describe 'Update governing APO Job form' do
    it 'has proper form input values' do
      expect(rendered).to have_css 'input[type="radio"][value="SetGoverningApoJob"]'
      expect(rendered).to have_css 'select[name="bulk_action[set_governing_apo][new_apo_id]"] option[value="druid:234"]'
    end
  end

  describe 'Reindex Job form' do
    it 'has proper form input values' do
      expect(rendered).to have_css 'input[type="radio"][value="RemoteIndexingJob"]'
    end
  end
end

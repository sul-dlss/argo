require 'spec_helper'

RSpec.describe 'bulk_actions/_form.html.erb' do
  before do
    @bulk_action = assign(:bulk_actions, create(:bulk_action))
    allow(view).to receive(:current_user).and_return(double(sunetid: 'esnowden'))
  end
  it 'form by default has action_type selected' do
    render
    expect(rendered)
      .to have_css 'input[type="radio"][value="DescmetadataDownloadJob"][checked="checked"]'
  end
  describe 'Release Object Job form' do
    it 'has proper form input values' do
      render
      expect(rendered).to have_css 'input[type="radio"][value="ReleaseObjectJob"]'
      expect(rendered).to have_css 'input[type="radio"][value="true"][checked="checked"][name="bulk_action[manage_release][tag]"]'
      expect(rendered).to have_css 'input[type="radio"][value="false"][name="bulk_action[manage_release][tag]"]'
      expect(rendered).to have_css 'select[name="bulk_action[manage_release][to]"]'
      expect(rendered).to have_css 'option[value="Searchworks"]'
      expect(rendered).to have_css 'input[value="self"][type="hidden"][name="bulk_action[manage_release][what]"]', visible: false
      expect(rendered).to have_css 'input[value="esnowden"][type="hidden"][name="bulk_action[manage_release][who]"]', visible: false
    end
  end
end

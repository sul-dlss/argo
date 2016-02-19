require 'spec_helper'

RSpec.describe 'bulk_actions/_form.html.erb' do
  before do
    @bulk_action = assign(:bulk_actions, create(:bulk_action))
  end
  it 'form by default has action_type selected' do
    render
    expect(rendered)
      .to have_css 'input[type="radio"][value="DescmetadataDownloadJob"][checked="checked"]'
  end
end

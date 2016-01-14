require 'rails_helper'

RSpec.describe "bulk_actions/show", type: :view do
  before(:each) do
    @bulk_action = assign(:bulk_action, BulkAction.create!(
      :action_type => "Action Type",
      :status => "Status",
      :log_name => "Log Name",
      :description => "Description",
      :druid_count_total => 1,
      :druid_count_success => 2,
      :druid_count_fail => 3
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(/Action Type/)
    expect(rendered).to match(/Status/)
    expect(rendered).to match(/Log Name/)
    expect(rendered).to match(/Description/)
    expect(rendered).to match(/1/)
    expect(rendered).to match(/2/)
    expect(rendered).to match(/3/)
  end
end

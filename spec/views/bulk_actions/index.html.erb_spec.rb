require 'rails_helper'

RSpec.describe "bulk_actions/index", type: :view do
  before(:each) do
    assign(:bulk_actions, [
      BulkAction.create!(
        :action_type => "Action Type",
        :status => "Status",
        :log_name => "Log Name",
        :description => "Description",
        :druid_count_total => 1,
        :druid_count_success => 2,
        :druid_count_fail => 3
      ),
      BulkAction.create!(
        :action_type => "Action Type",
        :status => "Status",
        :log_name => "Log Name",
        :description => "Description",
        :druid_count_total => 1,
        :druid_count_success => 2,
        :druid_count_fail => 3
      )
    ])
  end

  it "renders a list of bulk_actions" do
    render
    assert_select "tr>td", :text => "Action Type".to_s, :count => 2
    assert_select "tr>td", :text => "Status".to_s, :count => 2
    assert_select "tr>td", :text => "Log Name".to_s, :count => 2
    assert_select "tr>td", :text => "Description".to_s, :count => 2
    assert_select "tr>td", :text => 1.to_s, :count => 2
    assert_select "tr>td", :text => 2.to_s, :count => 2
    assert_select "tr>td", :text => 3.to_s, :count => 2
  end
end

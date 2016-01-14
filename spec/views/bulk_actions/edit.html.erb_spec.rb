require 'rails_helper'

RSpec.describe "bulk_actions/edit", type: :view do
  before(:each) do
    @bulk_action = assign(:bulk_action, BulkAction.create!(
      :action_type => "MyString",
      :status => "MyString",
      :log_name => "MyString",
      :description => "MyString",
      :druid_count_total => 1,
      :druid_count_success => 1,
      :druid_count_fail => 1
    ))
  end

  it "renders the edit bulk_action form" do
    render

    assert_select "form[action=?][method=?]", bulk_action_path(@bulk_action), "post" do

      assert_select "input#bulk_action_action_type[name=?]", "bulk_action[action_type]"

      assert_select "input#bulk_action_status[name=?]", "bulk_action[status]"

      assert_select "input#bulk_action_log_name[name=?]", "bulk_action[log_name]"

      assert_select "input#bulk_action_description[name=?]", "bulk_action[description]"

      assert_select "input#bulk_action_druid_count_total[name=?]", "bulk_action[druid_count_total]"

      assert_select "input#bulk_action_druid_count_success[name=?]", "bulk_action[druid_count_success]"

      assert_select "input#bulk_action_druid_count_fail[name=?]", "bulk_action[druid_count_fail]"
    end
  end
end

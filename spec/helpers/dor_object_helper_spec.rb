require 'spec_helper'

describe DorObjectHelper do
  class DummyClass
  end

  before(:all) do
    @dummy = DummyClass.new
    @dummy.extend DorObjectHelper
  end

  describe "render_status" do
    it "should build a basic status string" do
          lifecycle_data=Array.new
          lifecycle_data << 'registered:2011-10-24 10:41pm'
          doc={ 'lifecycle_display' => lifecycle_data }
          @dummy.render_status(doc).should == 'v1 Registered 2011-10-24 03:41pm'
    end
    it 'should include an embargo date if the item is embargoed' do
      lifecycle_data=Array.new
      lifecycle_data << 'registered:2011-10-24 10:41pm'
      embargo_data=Array.new
      embargo_data << 'embargoed until 2012-11-27 3:41pm'
      doc={ 'lifecycle_display' => lifecycle_data,'embargoMetadata_t' =>embargo_data }
			user=User.find_or_create_by_webauth(double('webauth', :login => 'mods', :attributes => { 'DISPLAYNAME' => 'Mods Asset'}))
			User.any_instance.stub(:is_admin).and_return(false)
			helper.stub(:current_user).and_return(user)
			helper.render_status(doc).should == 'v1 Registered 2011-10-24 03:41pm (embargoed until 2012-11-27 07:41am)'
    end
  	it 'should include the embargo update form if the item is embargoed and the user is an admin' do
      lifecycle_data=Array.new
      lifecycle_data << 'registered:2011-10-24 10:41pm'
      embargo_data=Array.new
      embargo_data << 'embargoed until 2012-11-27 3:41pm'
      doc={ 'lifecycle_display' => lifecycle_data,'embargoMetadata_t' =>embargo_data }
			user=User.find_or_create_by_webauth(double('webauth', :login => 'mods', :attributes => { 'DISPLAYNAME' => 'Mods Asset'}))
			User.any_instance.stub(:is_admin).and_return(true)
			helper.stub(:current_user).and_return(user)
			helper.render_status(doc).should match "datepicker"
    end
    it 'should not include an embargo date if the item was released from embargo' do
      lifecycle_data=Array.new
      lifecycle_data << 'registered:2011-10-24 10:41pm'
      embargo_data = 'released 2012-11-27 10:41pm'
      doc={ 'lifecycle_display' => lifecycle_data,'embargoMetadata_t' =>embargo_data }
      helper.render_status(doc).should == 'v1 Registered 2011-10-24 03:41pm'
    end
    it 'shoud handle version numbers in the lifecycle entries' do
      lifecycle_data=Array.new
      lifecycle_data << 'registered:2011-10-24 10:41pm'
      lifecycle_data << 'registered:2011-10-24 10:41pm;3'
      embargo_data = 'released 2012-11-27 10:41pm'
      doc={ 'lifecycle_display' => lifecycle_data,'embargoMetadata_t' =>embargo_data }
      helper.render_status(doc).should == 'v1 Registered 2011-10-24 03:41pm'
    end
    it 'should show the last step of the last version if there isnt a current version' do
      lifecycle_data=Array.new
      lifecycle_data << 'registered:2011-10-24 10:41pm;3'
      embargo_data = 'released 2012-11-27 10:41pm'
      doc={ 'lifecycle_display' => lifecycle_data,'embargoMetadata_t' =>embargo_data }
      helper.render_status(doc).should == 'v3 Registered 2011-10-24 03:41pm'
    end
  end
  describe 'can_open_version?' do
    it 'should say yes if the object is accessioned' do
      Dor::WorkflowService.stub(:get_lifecycle).and_return(true)
      Dor::WorkflowService.stub(:get_active_lifecycle).and_return(false)
      helper.can_open_version?('druid:something').should == true
    end
  end
  describe 'can_close_version?' do
    it 'should say yes if the item is open' do
      Dor::WorkflowService.stub(:get_active_lifecycle) do |dor, pid, lifecycle|
        if lifecycle == 'opened'
          true
        else
          false
        end
      end
      pid='druid:something'
      Dor::WorkflowService.get_active_lifecycle('dor', pid, 'opened').should == true
      Dor::WorkflowService.get_active_lifecycle('dor', pid, 'submitted').should ==false 
      helper.can_close_version?('druid:something').should == true
    end
  end
end
  

  
    

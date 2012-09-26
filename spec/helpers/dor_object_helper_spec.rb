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
          @dummy.render_status(doc).should == ' Registered 2011-10-24 03:41pm'
    end
    it 'should include an embargo date if the item is embargoed' do
      lifecycle_data=Array.new
      lifecycle_data << 'registered:2011-10-24 10:41pm'
      embargo_data=Array.new
      embargo_data << 'embargoed until 2012-11-27 3:41pm'
      doc={ 'lifecycle_display' => lifecycle_data,'embargoMetadata_t' =>embargo_data }
			user=User.find_or_create_by_webauth(double('webauth', :login => 'mods', :attributes => { 'DISPLAYNAME' => 'Møds Ässet'}))
			User.any_instance.stub(:is_admin).and_return(false)
			helper.stub(:current_user).and_return(user)
			helper.render_status(doc).should == ' Registered 2011-10-24 03:41pm (embargoed until 2012-11-27 07:41am)'
    end
  	it 'should include the embargo update form if the item is embargoed and the user is an admin' do
      lifecycle_data=Array.new
      lifecycle_data << 'registered:2011-10-24 10:41pm'
      embargo_data=Array.new
      embargo_data << 'embargoed until 2012-11-27 3:41pm'
      doc={ 'lifecycle_display' => lifecycle_data,'embargoMetadata_t' =>embargo_data }
			user=User.find_or_create_by_webauth(double('webauth', :login => 'mods', :attributes => { 'DISPLAYNAME' => 'Møds Ässet'}))
			User.any_instance.stub(:is_admin).and_return(true)
			helper.stub(:current_user).and_return(user)
			helper.render_status(doc).should match "datepicker"
    end
    it 'should not include an embargo date if the item was released from embargo' do
      lifecycle_data=Array.new
      lifecycle_data << 'registered:2011-10-24 10:41pm'
      embargo_data = 'released 2012-11-27 10:41pm'
      doc={ 'lifecycle_display' => lifecycle_data,'embargoMetadata_t' =>embargo_data }
      helper.render_status(doc).should == ' Registered 2011-10-24 03:41pm'
    end
  end
end
  

  
    

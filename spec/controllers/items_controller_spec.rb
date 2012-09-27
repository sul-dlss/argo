   require 'spec_helper'
   describe ItemsController do
		 
		 describe "#embargo_update" do
			 it "should 403 if you arent an admin" do
				subject.stub(:webauth).and_return(mock(:webauth_user, :login => 'sunetid', :logged_in? => true,:privgroup=>"nothing"))	
				post 'embargo_update', :client => {'format'=>'json','id'=>'oo201oo0001','date' => "12/19/2013"}
				response.code.should == "403"
			 end
			 it "should call Dor::Item.update_embargo" do
				User.stub(:webauth).and_return(mock(:webauth_user, :login => 'sunetid', :logged_in? => true,:privgroup=>ADMIN_GROUPS.first))
				User.stub(:is_admin?).and_return(true)
				Dor::Item.stub(:find).and_return(nil)
				runs=0
				Dor::Item.stub(:update_embargo).and_return(true)
				ItemsController.any_instance.stub(:embargo_update)do |a| runs+=1 end
				post 'embargo_update', :client => {'format'=>'json','id'=>'oo201oo0001','date' => "12/19/2013"}
				#should redirect
	#			runs.should ==1
				response.code.should == "302"
			 end
		 end
		end

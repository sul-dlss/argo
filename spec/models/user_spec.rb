# encoding: UTF-8

require 'spec_helper'

describe User do
  describe '.find_or_create_by_webauth' do
    it "should work" do
      mock_webauth = double('webauth', :login => 'asdf')
      user = User.find_or_create_by_webauth(mock_webauth)
      user.webauth.should == mock_webauth
    end
  end

  context "with webauth" do
    subject { User.find_or_create_by_webauth(double('webauth', :login => 'mods', :attributes => { 'DISPLAYNAME' => 'Møds Ässet'})) }

    describe "#login" do
      it "should get the sunetid from Webauth" do
        subject.login.should == 'mods'
      end
    end

    describe "#to_s" do
      it "should be the name from Webauth" do
        subject.to_s.should == 'Møds Ässet'
      end
    end
  end

  context "with REMOTE_USER" do
    subject { User.find_or_create_by_remoteuser('mods') }

    describe "#login" do
      it "should get the sunetid from Webauth" do
        subject.login.should == 'mods'
      end
    end

    describe "#to_s" do
      it "should be the name from Webauth" do
        subject.to_s.should == 'mods'
      end
    end
  end
  describe "is_admin" do
  	
  end
  describe "groups" do
  end
end

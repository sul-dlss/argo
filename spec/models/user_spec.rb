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

  describe "#to_s" do
    it "should be the name from Webauth" do
      mock_webauth = double('webauth', :attributes => { 'DISPLAYNAME' => 'Møds Ässet'})
      subject.should_receive(:webauth).and_return mock_webauth
      subject.to_s.should == 'Møds Ässet'
    end
  end
end

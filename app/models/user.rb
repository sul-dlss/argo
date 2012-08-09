class User < ActiveRecord::Base
# Connects this user object to Blacklights Bookmarks and Folders. 
 include Blacklight::User
 
 attr_accessor :webauth
 
 def self.find_or_create_by_webauth(webauth)
   result = self.find_or_create_by_sunetid(webauth.login)
   result.webauth = webauth
   result
 end
 
 def to_s
   webauth.attributes['DISPLAYNAME'] || webauth.login
 end
 
end

class User < ActiveRecord::Base
# Connects this user object to Blacklights Bookmarks and Folders. 
 include Blacklight::User
 
 attr_accessor :webauth
 
 def self.find_or_create_by_webauth(webauth)
   result = self.find_or_create_by_sunetid(webauth.login)
   result.webauth = webauth
   result
 end
 
 def self.find_or_create_by_remoteuser username
   result = self.find_or_create_by_sunetid(username)
   result
 end

 def to_s
   if webauth
     webauth.attributes['DISPLAYNAME'] || webauth.login
   else
     sunetid
   end
 end

 def login
   if webauth
     webauth.login
   else
     sunetid
   end
 end

end

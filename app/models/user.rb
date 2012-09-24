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

	def groups
		      perm_keys = ["sunetid:#{self.login}"]
		        if webauth and webauth.privgroup.present?
			          perm_keys += webauth.privgroup.split(/\|/).collect { |g| "workgroup:#{g}" }
			      end
						return perm_keys
	end
	def is_admin?
  	ADMIN_GROUPS.each do |group|
			if self.groups.include? group
				return true 
			end
    end
    return false
  end
 def login
   if webauth
     webauth.login
   else
     sunetid
   end
 end

end

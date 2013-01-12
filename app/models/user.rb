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
  
  @role_cache={}
  def roles pid
    if not @role_cache
      @role_cache={}
    end

    if @role_cache[pid]
      return @role_cache[pid]
    end
    known_roles=['dor-administrator', 'dor-viewer', 'dor-apo-creator', 'dor-apo-manager', 'dor-apo-depositor', 'dor-apo-reviewer', 'dor-apo-metadata', 'dor-apo-viewer']
    resp = Dor::SearchService.query('id:"'+ pid+ '"')['response']['docs'].first
    toret=[]
    #search for group based roles
    #this is a legacy role that has to be translated
    if(resp['apo_role_group_manager_t'] and (resp['apo_role_group_manager_t'] & groups).length > 0)
      toret << 'dor-apo-manager'
    end

    known_roles.each do |role|
      if(resp['apo_role_group_'+role+'_t'] and (resp['apo_role_group_' + role + '_t'] & groups).length >0)
        toret << role
      end
    end
    #now look to see if there are roles for this person by sunet id. groups actually contains the sunetid, so it is just looking at different solr fields
    #this is a legacy role that has to be translated
    if(resp['apo_role_person_manager_t'] and (resp['apo_role_person_manager_t'] & groups).length > 0)
      toret << 'dor-apo-manager'
    end

    known_roles.each do |role|
      if(resp['apo_role_person_'+role+'_t'] and (resp['apo_role_person_' + role + '_t'] & groups).length >0)
        toret << role
      end
    end
    #store this for now, there may be several role related calls 
    @role_cache[pid]=toret
    toret
  end
  #array of apos the user is allowed to view
  def permitted_apos 
    query=""
    known_roles=['dor-administrator', 'dor-viewer', 'dor-apo-creator', 'dor-apo-manager', 'dor-apo-depositor', 'dor-apo-reviewer', 'dor-apo-metadata', 'dor-apo-viewer']
    first=true
    groups.each do |group|
      if first
        query+=' '+group.gsub(':','\:')
        first=false
      else
        query+=' OR '+group.gsub(':','\:')
      end
    end
    q='apo_role_group_manager_t:('+ query + ') OR apo_role_person_manager_t:(' + query + ')'
    known_roles.each do |role|
      q+=' OR apo_role_group_'+role+'_t:('+query+')' 
    end
    resp = Dor::SearchService.query(q, {:rows => 100, :fl => 'id'})['response']['docs']
    pids=[]
    count=1
    resp.each do |doc|
      pids << doc['id']
    end
    pids  
  end
  
  @groups
  #create a set of groups in a cookie store to allow a repository admin to see the repository as if they had a different set of permissions
  def set_groups grps
    @groups=grps
  end
  def groups
    if @groups
      return @groups
    end
    perm_keys = ["sunetid:#{self.login}"]
    if webauth and webauth.privgroup.present?
      perm_keys += webauth.privgroup.split(/\|/).collect { |g| "workgroup:#{g}" }
    end
    return perm_keys
  end
  
  #is the user a repository wide administrator
  def is_admin
    ADMIN_GROUPS.each do |group|
      if self.groups.include? group
        return true 
      end
    end
    return false
  end
  
  #is the user a repository wide viewer
  def is_viewer
    VIEWER_GROUPS.each do |group|
      if self.groups.include? group
        return true 
      end
    end
    return false
  end
  #is the user a repo wide manager
  def is_manager
    MANAGER_GROUPS.each do |group|
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

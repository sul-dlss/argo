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
    resp = Dor::SearchService.query('id:"'+ pid+ '"')['response']['docs'].first
    if not resp
      resp={}
    end
    toret=[]
    #search for group based roles
    #this is a legacy role that has to be translated
    if(resp['apo_role_group_manager_t'] and (resp['apo_role_group_manager_t'] & groups).length > 0)
      toret << 'dor-apo-manager'
    end

    known_roles.each do |role|
      if(resp['apo_role_'+role+'_t'] and (resp['apo_role_' + role + '_t'] & groups).length >0)
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
  def known_roles
    ['dor-administrator', 'dor-viewer', 'dor-apo-creator', 'dor-apo-manager', 'dor-apo-depositor', 'dor-apo-reviewer', 'dor-apo-metadata', 'dor-apo-viewer']
  end

  def permitted_apos 
    query=""
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
      q+=' OR apo_role_'+role+'_t:('+query+')' 
    end
    resp = Dor::SearchService.query(q, {:rows => 100, :fl => 'id'})['response']['docs']
    pids=[]
    count=1
    resp.each do |doc|
      pids << doc['id']
    end
    pids  
  end
  def permitted_collections
    q = 'objectType_t:collection '
    qrys=[]
    permitted_apos.each do |pid|
      qrys << 'is_governed_by_s:"info:fedora/'+pid+'"'
    end
    q+=qrys.join " OR "
    result = Dor::SearchService.query(q, :rows => 99999, :fl => 'id,tag_t,dc_title_t').docs
    result.sort! do |a,b|
      a['dc_title_t'].to_s <=> b['dc_title_t'].to_s
    end
    res=[['None', '']]
    res+=result.collect do |doc|
      [Array(doc['dc_title_t']).first,doc['id'].to_s]
    end
    res
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
    #if this is an admin wanting to view the world as if they werent, accomidate them.
    if @groups
      return false
    end
    ADMIN_GROUPS.each do |group|
      if self.groups.include? group
        return true 
      end
    end
    return false
  end
  
  #is the user a repository wide viewer
  def is_viewer
    #if this is an admin wanting to view the world as if they werent, accomidate them.
    if @groups
      return false
    end
    VIEWER_GROUPS.each do |group|
      if self.groups.include? group
        return true 
      end
    end
    return false
  end
  #is the user a repo wide manager
  def is_manager
    #if this is an admin wanting to view the world as if they werent, accomidate them.
    if @groups
      return false
    end
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

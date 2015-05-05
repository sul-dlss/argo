class User < ActiveRecord::Base
  # Connects this user object to Blacklights Bookmarks and Folders.
  include Blacklight::User

  attr_accessor :webauth

  def self.find_or_create_by_webauth(webauth)
    result = self.find_or_create_by(:sunetid => webauth.login)
    result.webauth = webauth
    result
  end

  def self.find_or_create_by_remoteuser username
    result = self.find_or_create_by(:sunetid => username)
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
    ['dor-administrator', 'sdr-administrator', 'dor-viewer', 'sdr-viewer', 'dor-apo-creator', 'dor-apo-manager', 'dor-apo-depositor', 'dor-apo-reviewer', 'dor-apo-metadata', 'dor-apo-viewer']
  end

  def permitted_apos
    query = ""
    first = true
    groups.each do |group|
      if first
        query += ' ' + group.gsub(':','\:')
        first = false
      else
        query += ' OR ' + group.gsub(':','\:')
      end
    end
    q = 'apo_role_group_manager_t:('+ query + ') OR apo_role_person_manager_t:(' + query + ')'
    known_roles.each do |role|
      q += ' OR apo_role_'+role+'_t:('+query+')'
    end
    if is_admin
      q = 'objectType_ssim:adminPolicy'
    end
    resp = Dor::SearchService.query(q, {:rows => 1000, :fl => 'id', :fq => '!project_tag_ssim:"Hydrus"'})['response']['docs']
    pids = []
    count = 1
    resp.each do |doc|
      pids << doc['id']
    end
    pids
  end

  def permitted_collections
    q = 'objectType_ssim:collection AND !project_tag_ssim:"Hydrus" '
    qrys=[]
    permitted_apos.each do |pid|
      qrys << 'is_governed_by_ssim:"info:fedora/'+pid+'"'
    end
    if not is_admin
      q+=qrys.join " OR "
    end
    result= Blacklight.solr.find({:q => q, :rows => 1000, :fl => 'id,tag_ssim,dc_title_t'}).docs

    #result = Dor::SearchService.query(q, :rows => 1000, :fl => 'id,tag_ssim,dc_title_t').docs
    result.sort! do |a,b|
      a['dc_title_t'].to_s <=> b['dc_title_t'].to_s
    end
    #puts 'qry '+result.first['dc_title_t'].encoding.inspect
    res=[['None', '']]
    res+=result.collect do |doc|
      [Array(doc['dc_title_t']).first+ ' (' + doc['id'].to_s + ')',doc['id'].to_s]
    end
    res.each do |ar|
      ar[0] = chomp_title ar.first
    end
    res
  end

  #this is a nasty way to deal with the bizzare ascii results coming from solr. Upgrading to blacklight 4.2 looks like it will remove the need for this
  def chomp_title title
    title.encode("UTF-8", :invalid => :replace, :undef => :replace, :replace => "?")
  end

  @groups_to_impersonate
  #create a set of groups in a cookie store to allow a repository admin to see the repository as if they had a different set of permissions
  def set_groups_to_impersonate grps
    @groups_to_impersonate = grps
  end

  def groups
    return @groups_to_impersonate if @groups_to_impersonate

    perm_keys = ["sunetid:#{self.login}"]
    if webauth and webauth.privgroup.present?
      perm_keys += webauth.privgroup.split(/\|/).collect { |g| "workgroup:#{g}" }
    end

    return perm_keys
  end

  def belongs_to_listed_group? group_list
    group_list.each do |group|
      if self.groups.include? group
        return true
      end
    end
    return false
  end

  #is the user a repository wide administrator
  def is_admin
    return belongs_to_listed_group? ADMIN_GROUPS
  end

  #is the user a repository wide viewer
  def is_viewer
    return belongs_to_listed_group? VIEWER_GROUPS
  end

  #is the user a repo wide manager
  def is_manager
    return belongs_to_listed_group? MANAGER_GROUPS
  end

  def login
    if webauth
      webauth.login
    else
      sunetid
    end
  end
end

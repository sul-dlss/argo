namespace :argo do
  directives = [
    'AuthType WebAuth',
    'Require valid-user',
    'WebAuthLdapAttribute suAffiliation',
    'WebAuthLdapAttribute displayName',
    'WebAuthLdapAttribute mail'
  ]
  task :update_privgroups => :environment do
    resp = Dor::SearchService.gsearch(:q=>'object_type_field:adminPolicy', :rows=>'0',
      :facet=>'on', :'facet.field'=>'apo_register_permissions_facet', :'facet.prefix'=>'workgroup:',
      :'facet.mincount'=>'1', :'facet.limit'=>'-1', :wt=>'json')
    facets = resp['facet_counts']['facet_fields']['apo_register_permissions_facet']
    priv_groups = facets.select { |v| v =~ /^workgroup:/ }
    directives += priv_groups.collect { |v| "WebAuthLdapPrivgroup #{v.split(/:/,2).last}" }.sort
    File.open(File.join(Rails.root, 'public/auth/.htaccess'),'w') do |htaccess|
      htaccess.puts directives.join("\n")
    end
  end
end
namespace :argo do
  directives = [
    'AuthType WebAuth',
    'Require privgroup dlss:argo-access',
    'WebAuthLdapAttribute suAffiliation',
    'WebAuthLdapAttribute displayName',
    'WebAuthLdapAttribute mail',
  ]
  desc "Update the .htaccess file from indexed APOs"
  task :htaccess => :environment do
    resp = Dor::SearchService.gsearch(:q=>'object_type_field:adminPolicy', :rows=>'0',
      :facet=>'on', :'facet.field'=>'apo_register_permissions_facet', :'facet.prefix'=>'workgroup:',
      :'facet.mincount'=>'1', :'facet.limit'=>'-1', :wt=>'json')
    facets = resp['facet_counts']['facet_fields']['apo_register_permissions_facet']
    priv_groups = facets.select { |v| v =~ /^workgroup:/ }
    directives += priv_groups.collect { |v| 
      ["Require privgroup #{v.split(/:/,2).last}", "WebAuthLdapPrivgroup #{v.split(/:/,2).last}"]
    }.flatten
    File.open(File.join(Rails.root, 'public/.htaccess'),'w') do |htaccess|
      htaccess.puts directives.sort.join("\n")
    end
    File.unlink('public/auth/.htaccess') if File.exists?('public/auth/.htaccess')
  end
end
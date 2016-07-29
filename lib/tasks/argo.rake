def apo_field_default
  'apo_register_permissions_ssim'
end

def get_workgroups_facet(apo_field = nil)
  apo_field = apo_field_default() if apo_field.nil?
  resp = Dor::SearchService.query('objectType_ssim:adminPolicy', :rows => 0,
    :facets => { :fields => [apo_field] },
    :'facet.prefix'   => 'workgroup:',
    :'facet.mincount' => 1,
    :'facet.limit'    => -1 )
  resp.facets.find { |f| f.name == apo_field }
end

desc 'Get application version'
task :app_version do
  puts File.read(File.expand_path('../../../VERSION', __FILE__)).strip
end

namespace :argo do
  desc "Bump Argo's version number before release"
  task :bump_version, [:level] do |t, args|
    levels = %w(major minor patch rc)
    version_file = File.expand_path('../../../VERSION', __FILE__)
    version = File.read(version_file)
    version = version.split(/\./)
    index = levels.index(args[:level] || (version.length == 4 ? 'rc' : 'patch'))
    version.pop if version.length == 4 && index < 3
    if index == 3
      rc = version.length == 4 ? version.pop : 'rc0'
      rc.sub!(/^rc(\d+)$/) { |m| "rc#{$1.to_i + 1}" }
      version << rc
      puts version.inspect
    else
      version[index] = version[index].to_i + 1
      (index + 1).upto(2) { |i| version[i] = '0' }
    end
    version = version.join('.')
    File.open(version_file, 'w') { |f| f.write(version) }
    $stderr.puts "Version bumped to #{version}"
  end

  # the .htaccess file lists the workgroups that we recognize as relevant to argo.
  # if a user is in a workgroup, and that workgroup is listed in the .htaccess file,
  # the name of the workgroup will be in a list of workgroups for the user, passed along
  # with other webauth info in the request headers.  we use the list of workgroups a user is
  # in (as well as the user's sunetid) to determine what they can see and do in argo.
  # NOTE: at present (2015-11-06), this rake task is run regularly by a cron job, so that
  # the .htaccess file keeps up with workgroup names as listed on APOs in use in argo.
  desc 'Update the .htaccess file from indexed APOs'
  task :htaccess => :environment do
    directives = ['AuthType WebAuth',
                  'Require privgroup dlss:argo-access',
                  'WebAuthLdapAttribute suAffiliation',
                  'WebAuthLdapAttribute displayName',
                  'WebAuthLdapAttribute mail']

    directives += (File.readlines(File.join(Rails.root, 'config/default_htaccess_directives')) || [])
    facet = get_workgroups_facet()
    unless facet.nil?
      facets = facet.items.map(&:value)
      priv_groups = facets.select { |v| v =~ /^workgroup:/ }
      # we always want these built-in groups to be part of .htaccess
      priv_groups += User::ADMIN_GROUPS
      priv_groups += User::MANAGER_GROUPS
      priv_groups += User::VIEWER_GROUPS
      directives += priv_groups.uniq.map { |v|
        ["Require privgroup #{v.split(/:/, 2).last}", "WebAuthLdapPrivgroup #{v.split(/:/, 2).last}"]
      }.flatten

      File.open(File.join(Rails.root, 'public/.htaccess'), 'w') do |htaccess|
        htaccess.puts directives.sort.join("\n")
      end
      File.unlink('public/auth/.htaccess') if File.exist?('public/auth/.htaccess')
    end
  end  # :htaccess

  desc 'Update completed/archived workflow counts'
  task :update_archive_counts => :environment do |t|
    Dor.find_all('objectType_ssim:workflow').each(&:update_index)
  end

  desc 'Reindex all DOR objects to Solr'
  task :reindex_all => [:environment] do |t, args|
    Argo::BulkReindexer.reindex_all
  end

  desc "List APO workgroups from Solr (#{apo_field_default()})"
  task :workgroups => :environment do
    facet = get_workgroups_facet()
    puts "#{facet.items.count} Workgroups:\n#{facet.items.map(&:value).join(%(\n))}"
  end


end # :argo

# frozen_string_literal: true

def apo_field_default
  'apo_register_permissions_ssim'
end

# @return [#keys]
def workgroups_facet(apo_field = nil)
  apo_field = apo_field_default() if apo_field.nil?
  resp = Dor::SearchService.query('objectType_ssim:adminPolicy', rows: 0,
                                                                 'facet.field': apo_field,
                                                                 'facet.prefix': 'workgroup:',
                                                                 'facet.mincount': 1,
                                                                 'facet.limit': -1,
                                                                 'json.nl': 'map')
  resp['facet_counts']['facet_fields'][apo_field] || {}
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

  desc 'Update completed/archived workflow counts'
  task update_archive_counts: :environment do |t|
    Dor.find_all('objectType_ssim:workflow').each(&:update_index)
  end

  desc 'Reindex all DOR objects to Solr'
  task reindex_all: [:environment] do |t, args|
    Argo::BulkReindexer.reindex_all
  end

  desc "List APO workgroups from Solr (#{apo_field_default()})"
  task workgroups: :environment do
    facet = workgroups_facet()
    puts "#{facet.length} Workgroups:\n#{facet.keys.join(%(\n))}"
  end
end # :argo

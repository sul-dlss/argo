# frozen_string_literal: true

def apo_field_default
  'apo_register_permissions_ssim'
end

# @return [#keys]
def workgroups_facet(apo_field = nil)
  apo_field = apo_field_default if apo_field.nil?
  resp = SearchService.query('objectType_ssim:adminPolicy', rows: 0,
                                                            "facet.field": apo_field,
                                                            "facet.prefix": 'workgroup:',
                                                            "facet.mincount": 1,
                                                            "facet.limit": -1,
                                                            "json.nl": 'map')
  resp['facet_counts']['facet_fields'][apo_field] || {}
end

desc 'Get application version'
task app_version: :environment do
  puts File.read(File.expand_path('../../VERSION', __dir__)).strip
end

namespace :argo do
  desc 'Create test items, specify number to create as argument'
  task :register_items, [:n] => :environment do |_t, args|
    raise '*** Only works in development mode!' unless Rails.env.development?

    require_relative '../../spec/support/create_strategy_repository_pattern'
    require_relative '../../spec/support/item_method_sender'

    n = args[:n].to_i
    n.times { FactoryBot.create_for_repository(:persisted_item) }
  end

  desc 'Seed APO, collection and item, useful for local development'
  task seed_data: :environment do
    raise '*** Only works in development mode!' unless Rails.env.development?

    require_relative '../../spec/support/create_strategy_repository_pattern'
    require_relative '../../spec/support/item_method_sender'
    require_relative '../../spec/support/apo_method_sender'
    require_relative '../../spec/support/reset_solr'

    $stdout.puts 'This will clear the Solr repo. Are you sure? [y/n]:'
    if $stdin.gets.chomp == 'y'
      ResetSolr.reset_solr
      FactoryBot.create_for_repository(:agreement)
      FactoryBot.create_for_repository(:persisted_item)
      FactoryBot.create_for_repository(:persisted_apo,
                                       roles: [{ name: 'dor-apo-manager',
                                                 members: [{ identifier: 'sdr:administrator-role',
                                                             type: 'workgroup' }] }])
    else
      $stdout.puts 'stopping'
    end
  end

  desc "Bump Argo's version number before release"
  task :bump_version, [:level] => :environment do |_t, args|
    levels = %w[major minor patch rc]
    version_file = File.expand_path('../../VERSION', __dir__)
    version = File.read(version_file)
    version = version.split('.')
    index = levels.index(args[:level] || (version.length == 4 ? 'rc' : 'patch'))
    version.pop if version.length == 4 && index < 3
    if index == 3
      rc = version.length == 4 ? version.pop : 'rc0'
      rc.sub!(/^rc(\d+)$/) { |_m| "rc#{Regexp.last_match(1).to_i + 1}" }
      version << rc
      puts version.inspect
    else
      version[index] = version[index].to_i + 1
      (index + 1).upto(2) { |i| version[i] = '0' }
    end
    version = version.join('.')
    File.write(version_file, version)
    warn "Version bumped to #{version}"
  end

  desc "List APO workgroups from Solr (#{apo_field_default})"
  task workgroups: :environment do
    facet = workgroups_facet
    puts "#{facet.length} Workgroups:\n#{facet.keys.join(%(\n))}"
  end
end # :argo

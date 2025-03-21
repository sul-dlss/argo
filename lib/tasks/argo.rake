# frozen_string_literal: true

def apo_field_default
  'apo_register_permissions_ssim'
end

# @return [#keys]
def workgroups_facet(apo_field = nil)
  apo_field = apo_field_default if apo_field.nil?
  resp = SearchService.query('objectType_ssim:adminPolicy', rows: 0,
                                                            'facet.field': apo_field,
                                                            'facet.prefix': 'workgroup:',
                                                            'facet.mincount': 1,
                                                            'facet.limit': -1,
                                                            'json.nl': 'map')
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
      FactoryBot.create_for_repository(:persisted_item)
    else
      $stdout.puts 'stopping'
    end
  end

  desc "List APO workgroups from Solr (#{apo_field_default})"
  task workgroups: :environment do
    facet = workgroups_facet
    puts "#{facet.length} Workgroups:\n#{facet.keys.join(%(\n))}"
  end
end

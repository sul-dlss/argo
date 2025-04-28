# frozen_string_literal: true

# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).

# Prevent executing this code in the production Rails env, which is what we use in deployed environments.
if Rails.env.local?
  require_relative '../spec/support/create_strategy_repository_pattern'
  require_relative '../spec/support/item_method_sender'
  require_relative '../spec/support/apo_method_sender'
  require_relative '../spec/support/reset_solr'

  $stdout.puts 'Clearing the Solr repo.'
  ResetSolr.reset_solr
  FactoryBot.create_for_repository(:agreement)
  FactoryBot.create_for_repository(:persisted_apo,
                                   roles: [{ name: 'dor-apo-manager',
                                             members: [{ identifier: 'sdr:administrator-role',
                                                         type: 'workgroup' }] }])
end

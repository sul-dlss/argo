# frozen_string_literal: true

def version_service(druid:)
  VersionService.new(druid: druid)
end

namespace :decommission do
  desc 'Decommission items by druid'
  task :item, %i[druid sunetid reason] => :environment do |_t, args|
    raise '*** druid, sunetid, and reason are required arguments' if args[:druid].nil? || args[:sunetid].nil? || args[:reason].nil?

    druid = args[:druid]
    sunetid = args[:sunetid]
    reason = args[:reason]

    DecommissionService.new(druid:, reason:, sunetid:).decommission
  rescue Dor::Services::Client::UnprocessableContentError => e
    puts "Failed to decommission #{args[:druid]}: #{e.message}"
  end
end

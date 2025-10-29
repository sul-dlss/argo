# frozen_string_literal: true

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

  task :items, %i[file sunetid reason] => :environment do |_t, args|
    raise '*** file is a required argument' if args[:file].nil?

    file = args[:file]
    CSV.open("log/decommission_items_#{Time.now.strftime('%Y%m%d%H%M%S')}.csv", 'w', write_headers: true, headers: %w[druid status message]) do |log|
      CSV.read(file, headers: true).each do |row|
        druid = row['druid']
        sunetid = row['sunetid'] || args[:sunetid]
        reason = row['reason'] || args[:reason]

        DecommissionService.new(druid:, reason:, sunetid:).decommission
        log << [druid, 'SUCCESS', 'Decommissioned successfully']
      rescue Error => e
        log << [druid, 'FAILURE', e.message]
      end
    end
  end
end

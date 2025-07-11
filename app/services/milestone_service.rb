# frozen_string_literal: true

# Retrieves object milestones from the Dor Workflow Service
class MilestoneService
  def self.milestones_for(druid:)
    {}.tap do |milestone_hash|
      Dor::Services::Client.object(druid).milestones.list.each do |milestone|
        milestone_hash[milestone[:version]] ||= ActiveSupport::OrderedHash[
          'registered' => {}, # each of these *could* have :display and :time elements
          'opened' => {},
          'submitted' => {},
          'published' => {},
          'deposited' => {},
          'accessioned' => {}
        ]
        milestone_hash[milestone[:version]].delete(milestone[:version] == '1' ? 'opened' : 'registered') # only version 1 has 'registered'
        milestone_hash[milestone[:version]][milestone[:milestone]] = {
          time: milestone[:at]
        }
      end
    end
  end
end

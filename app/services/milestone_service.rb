# frozen_string_literal: true

# Retrieves object milestones from the Dor Workflow Service
class MilestoneService
  def self.milestones_for(druid:)
    @druid = druid
    hash = {}
    milestone_client.each do |milestone|
      hash[milestone[:version]] ||= ActiveSupport::OrderedHash[
        'registered' => {}, # each of these *could* have :display and :time elements
        'opened' => {},
        'submitted' => {},
        'described' => {},
        'published' => {},
        'deposited' => {},
        'accessioned' => {}
      ]
      hash[milestone[:version]].delete(milestone[:version] == '1' ? 'opened' : 'registered') # only version 1 has 'registered'
      hash[milestone[:version]][milestone[:milestone]] = {
        time: milestone[:at]
      }
    end
    hash
  end

  def self.milestone_client
    WorkflowClientFactory.build.milestones(druid: @druid)
  end

  private_class_method :milestone_client
end

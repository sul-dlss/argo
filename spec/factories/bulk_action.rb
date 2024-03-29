# frozen_string_literal: true

FactoryBot.define do
  factory :bulk_action do
    action_type { 'RemoteIndexingJob' }
    user
    log_name { 'tmp/log.txt' }
  end
end

# frozen_string_literal: true

# Removes an object from SDR.
class PurgeService
  # @param [String] druid
  # @param [String] user_name
  def self.purge(druid:, user_name:)
    Dor::Services::Client.object(druid).destroy(user_name:)
  end
end

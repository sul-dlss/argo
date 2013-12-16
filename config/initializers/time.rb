
require 'moab'
require 'time'
class Time
  # @return [String] The datetime in ISO 8601 format
  def to_s arg=nil
    self.utc.iso8601
  end
end

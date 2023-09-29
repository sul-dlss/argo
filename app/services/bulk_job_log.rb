# frozen_string_literal: true

class BulkJobLog
  def self.open(log_name, &)
    File.open(log_name, 'a', &)
  end
end

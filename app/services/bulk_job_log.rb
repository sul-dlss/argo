# frozen_string_literal: true

class BulkJobLog
  def self.open(log_name, &block)
    File.open(log_name, 'a', &block)
  end
end

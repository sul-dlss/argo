##
# can be used to create a bunch of jobs that just write to a file, to test
# things like whether the job mechanism adheres to strict ordering of groups (i.e. 
# the tasks in a group are entirely complete before the next group is started).
class SimpleWriteJob < ActiveJob::Base
  queue_as :simple_write

  attr_reader :max_sleep_time, :log_filename

  def initialize(log_val, max_sleep_time = 10, log_filename = 'tmp/simple_job.log')
    @log_val = log_val
    @max_sleep_time = max_sleep_time
    @log_filename = log_filename
  end

  def perform
    sleep(max_sleep_time)

    File.open(log_filename, 'a') do |log|
      log.puts "#{@log_val}"
    end
  end
end


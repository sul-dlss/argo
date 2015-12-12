module Argo
  class SimpleWriteQueuer
    def self.queue_simple_write_jobs(num_groups = 10, group_size = 100)
      (1..num_groups).each do |group_num|
        (1..group_size).each do
          SimpleWriteJob.delay(priority: group_num).perform_later group_num
        end
      end
    end

    def self.queue_simple_write_jobs_in_groups(num_groups = 10, group_size = 100)
      job_groups = (1..num_groups).map do |group_num| 
        job_group = Delayed::JobGroups::JobGroup.create!(blocked: true)
        # use on_completion_job to queue a job that unblocks the next group (will need to create a new job class)
      end

      job_groups.each_with_index do |job_group, group_num|
        (1..group_size).each do
          job_group.enqueue SimpleWriteJob.new(group_num, priority: group_num)
          job_group.mark_queueing_complete
        end
      end

      # unblock the first group to start things off
    end
  end
end

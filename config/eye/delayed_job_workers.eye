cwd = File.expand_path(File.join(File.dirname(__FILE__), %w[ ../ ../ ]))

Eye.config do
  logger "#{cwd}/log/eye.log"
end

# best to use 2 or more workers so process naming scheme is as expected, see below
workers_count = ENV['ARGO_DELAYED_JOB_WORKER_COUNT'].to_i
Logger.info "workers_count=#{workers_count}"

Eye.application 'delayed_job' do
  working_dir cwd
  stop_on_delete true

  group 'workers' do
    # workers can take a while to restart, especially when they've consumed a lot of memory
    start_timeout 90.seconds
    start_grace 10.seconds
    stop_timeout 90.seconds
    stop_grace 10.seconds
    restart_timeout 90.seconds
    restart_grace 10.seconds

    stdall "#{cwd}/log/eye.dj_workers.log"

    # NOTE: if 'delayed_job start' is invoked without a count (which happens when capistrano is configured to
    # start 1 worker on deploy), it won't give the one process it creates a number (e.g. "delayed_job" instead of
    # "delayed_job.0").  in that situation, this configuration will have trouble monitoring the worker (and will
    # start its own "delayed_job.0" by calling "delayed_job start 1", because it will think no workers are running).
    # as such, it's best to just use this configuration with two or more workers.
    (0..workers_count-1).each do |i|
      process "delayed_job.#{i}" do
        pid_file "tmp/pids/delayed_job.#{i}.pid"
        start_command "bundle exec bin/delayed_job start -i #{i}"
        restart_command "bundle exec bin/delayed_job restart -i #{i}"
        stop_command "bundle exec bin/delayed_job stop -i #{i}"

        # we don't need to know immediately when a worker exceeds the limit,
        # so every 5 min is fine.  but we expect memory usage to pretty much
        # be monotonically increasing (prob due to memory leak), so don't bother
        # checking multiple times before restarting.
        check :memory, every: 300.seconds, below: 3000.megabytes, times: 1
      end
    end
  end
end

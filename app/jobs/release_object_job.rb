##
# Job to add release and then release a Dor Object
class ReleaseObjectJob < GenericJob
  queue_as :release_object

  attr_reader :manage_release, :pids, :groups
  ##
  # This is a shameless green approach to a job that calls release from dor
  # services app and then kicks off release WF.
  # @param [Integer] bulk_action_id GlobalID for a BulkAction object
  # @param [Hash] params additional parameters that an Argo job may need
  # @option params [Array] :pids required list of pids
  # @option params [Hash] :manage_release required Hash of release options
  # @option manage_release [String] :to required release to target
  # @option manage_release [String] :who required username of releaser
  # @option manage_release [String] :what required type of release (self, collection)
  # @option manage_release [String] :tag required (true, false)
  # @option params [Array] :groups the groups the user belonged to when the started the job. Required for permissions check
  def perform(bulk_action_id, params)
    @manage_release = params[:manage_release]
    @groups = params[:groups]
    @pids = params[:pids]
    with_bulk_action_log do |log|
      log.puts("#{Time.current} Starting ReleaseObjectJob for BulkAction #{bulk_action_id}")
      update_druid_count

      pids.each do |current_druid|
        log.puts("#{Time.current} Beginning ReleaseObjectJob for #{current_druid}")
        unless can_manage?(current_druid)
          log.puts("#{Time.current} Not authorized for #{current_druid}")
          next
        end
        log.puts("#{Time.current} Adding release tag for #{manage_release['to']}")
        begin
          response = post_to_release(current_druid, params_to_body(manage_release))
          if response.status == 201
            log.puts("#{Time.current} Release tag added successfully")
          else
            log.puts("#{Time.current} Release tag failed POST #{response.env.url}, status: #{response.status}")
            bulk_action.increment(:druid_count_fail).save
            next
          end
        rescue Faraday::TimeoutError, Faraday::ConnectionFailed => e
          log.puts("#{Time.current} Release tag failed POST #{e.class} #{e.message}")
          bulk_action.increment(:druid_count_fail).save
          next
        end
        log.puts("#{Time.current} Trying to start release workflow")
        begin
          response = post_to_release_wf(current_druid)
          if response.status == 201
            log.puts("#{Time.current} Workflow creation successful")
            bulk_action.increment(:druid_count_success).save
          else
            log.puts("#{Time.current} Workflow creation failed POST #{response.env.url}, status: #{response.status}")
            bulk_action.increment(:druid_count_fail).save
          end
        rescue Faraday::TimeoutError, Faraday::ConnectionFailed => e
          log.puts("#{Time.current} Workflow creation failed POST #{e.class} #{e.message}")
          bulk_action.increment(:druid_count_fail).save
        end
      end
      log.puts("#{Time.current} Finished ReleaseObjectJob for BulkAction #{bulk_action_id}")
    end
  end

  def can_manage?(pid)
    ability.can?(:manage_item, Dor.find(pid))
  end

  private

  def ability
    @ability ||= begin
      user = bulk_action.user
      # Since a user doesn't persist its groups, we need to pass the groups in here.
      user.set_groups_to_impersonate(groups)
      Ability.new(user)
    end
  end

  def params_to_body(params)
    {
      to: params['to'],
      who: params['who'],
      what: params['what'],
      release: string_to_boolean(params['tag'])
    }.to_json
  end

  def string_to_boolean(string)
    case string
    when 'true'
      true
    when 'false'
      false
    end
  end

  def connection
    Faraday.new(Settings.DOR_SERVICES_URL)
  end

  def post_to_release(druid, body)
    connection.post do |req|
      req.url "/dor/v1/objects/#{druid}/release_tags"
      req.headers['Content-Type'] = 'application/json'
      req.body = body
    end
  end

  def post_to_release_wf(druid)
    connection.post do |req|
      req.url "/dor/v1/objects/#{druid}/apo_workflows/releaseWF"
    end
  end

  def update_druid_count
    bulk_action.update(druid_count_total: pids.length)
    bulk_action.save
  end
end

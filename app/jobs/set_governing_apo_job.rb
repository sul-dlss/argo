##
# job to move an object to a new governing APO
class SetGoverningApoJob < GenericJob
  queue_as :set_governing_apo

  attr_reader :pids, :new_apo_id, :webauth

  def perform(bulk_action_id, params)
    @new_apo_id = params[:set_governing_apo]['new_apo_id']
    @webauth = OpenStruct.new params[:webauth]

    @pids = params[:pids]

    with_bulk_action_log do |log|
      log.puts("#{Time.current} Starting SetGoverningApoJob for BulkAction #{bulk_action_id}")
      update_druid_count

      pids.each do |current_druid|
        log.puts("#{Time.current} SetGoverningApoJob: Starting update for #{current_druid} (bulk_action.id=#{bulk_action_id})")
        set_governing_apo_and_index_safely(current_druid, log)
        log.puts("#{Time.current} SetGoverningApoJob: Finished update for #{current_druid} (bulk_action.id=#{bulk_action_id})")
      end

      Dor::SearchService.solr.commit
      log.puts("#{Time.current} Finished SetGoverningApoJob for BulkAction #{bulk_action_id}")
    end
  end

  private

  def set_governing_apo_and_index_safely(current_druid, log)
    current_obj = Dor.find(current_druid)

    unless can_set_governing_apo?(current_obj)
      log.puts("#{Time.current} SetGoverningApoJob: Unexpected error for #{current_druid} (bulk_action.id=#{bulk_action.id}): user not allowed to move to target apo")
      bulk_action.increment(:druid_count_fail).save
      return
    end

    open_new_version(current_obj, log, @webauth) unless current_obj.allows_modification?

    current_obj.admin_policy_object = Dor.find(new_apo_id)
    current_obj.identityMetadata.adminPolicy = nil if current_obj.identityMetadata.adminPolicy # no longer supported, erase if present as a bit of remediation
    current_obj.save
    Dor::SearchService.solr.add current_obj.to_solr

    log.puts("#{Time.current} SetGoverningApoJob: Successfully updated #{current_druid} (bulk_action.id=#{bulk_action.id})")
    bulk_action.increment(:druid_count_success).save
  rescue => e
    log.puts("#{Time.current} SetGoverningApoJob: Unexpected error for #{current_druid} (bulk_action.id=#{bulk_action.id}): #{e}")
    bulk_action.increment(:druid_count_fail).save
  end

  def can_set_governing_apo?(obj)
    ability.can?(:manage_governing_apo, obj, new_apo_id)
  end

  def ability
    @ability ||= Ability.new(User.find_or_create_by_webauth(webauth))
  end

  def update_druid_count
    bulk_action.update(druid_count_total: pids.length)
    bulk_action.save
  end

  def open_new_version(object, log, webauth)
    if DorObjectWorkflowStatus.new(object.pid).can_open_version?
      begin
        vers_md_upd_info = {
          :significance => 'minor',
          :description => 'Set new governing APO',
          :opening_user_name => webauth[:login].to_s
        }
        object.open_new_version({:vers_md_upd_info => vers_md_upd_info})
      rescue Dor::Exception => e
        log.puts("#{Time.current} Failed to open new version for #{object.pid} (bulk_action.id=#{bulk_action.id}): #{e}")
        return
      end
    else
      log.puts("#{Time.current} Unable to open new version for #{object.pid} (bulk_action.id=#{bulk_action.id})")
    end
  end
end

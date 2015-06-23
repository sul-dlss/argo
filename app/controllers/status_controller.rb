class StatusController < ApplicationController
  include ActionView::Helpers::DateHelper
  skip_before_filter :authorize!

  def log
    if check_recently_indexed
      render :status=>200, :text=> 'All good! <br/>'
      return
    end
    if params[:test_obj].nil?
      render :status=>500, :text=> 'Nothing indexed recently.'
      return
    end
    test_item = Dor::Item.find(params[:test_obj])
    test_item.identityMetadata.content_will_change!  # mark as dirty
    test_item.save
    secs = params[:sleep].nil? ? 10.0 : params[:sleep].to_i  # allow override to speed testing
    sleep secs
    if check_recently_indexed
      render :status=>200, :text=> "All good! <br/>Saved #{params[:test_obj]}"
      return
    else
      render :status=>500, :text=> "Nothing indexed recently. Even after saving '#{params[:test_obj]}'."
      return
    end
  rescue ActiveFedora::ObjectNotFoundError
    render :status=>404, :text=> "No object '#{params[:test_obj]}' found"
  end

  def memcached
    Rails.cache.fetch("cache_test", :expires_in => 1.minute) do
      'hello world'
    end
    if Rails.cache.fetch("cache_test", :expires_in => 1.minute).nil?
      render :status=>500, :text=>'Cache lookup failed'
      return
    end
    if Rails.cache.fetch("cache_test", :expires_in => 1.minute) == 'hello world'
      render :status=>200, :text=>'Success'
      return
    end
    render :status=>500, :text=>'Incorrect value!'
  end

  protected

  # @return [Boolean]
  def check_recently_indexed
    docs = Dor::SearchService.query("indexed_at_dt:[NOW-15MINUTES TO NOW]", {:rows => 1, :fl => 'indexed_at_dt'})['response']['docs']
    docs.length == 1
  end

  def check_logs
    log_file = File.new(LOG_FILE,'r')
    txt=''
    zone = ActiveSupport::TimeZone.new("Pacific Time (US & Canada)")
    params[:minutes] ||= '15'
    cutoff_time = params[:minutes].to_i.minutes.ago
    cutoff_time=DateTime.parse(cutoff_time.to_s).in_time_zone(zone)

    while(line=log_file.gets)

      #check whether this is a successful index
      if line.match 'updated'
        #parse the time to see if it was within the last params[:interval] minutes
        timestamp=line.split('[').last.split('\.').first
        this_run=DateTime.parse(timestamp).change(:offset => zone.formatted_offset)
        if(this_run > cutoff_time)
          return true
        else
          txt=line
        end
      end
    end
    return txt
  end

end

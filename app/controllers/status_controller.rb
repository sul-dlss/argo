class StatusController < ApplicationController
  include ActionView::Helpers::DateHelper
  skip_before_filter :authorize!

  def log
    if check_logs !=true
      if not params[:test_obj].nil?
        test_item=Dor::Item.find(params[:test_obj])
        test_item.identityMetadata.dirty=true
        test_item.save
        sleep 5.0
        txt= check_logs
        if txt==true	
          render :status=>200, :text=> 'All good!	<br>'
          return
        else
          render :status=>500, :text=>'Nothing indexed in last '+ params[:minutes] +' minutes, last indexed was:<br> '+txt
          return
        end
      end
    else
      render :status=>200, :text=> 'All good!	<br>'
      return
    end
    render :status=>500, :text=>'Nothing indexed in last '+ params[:minutes]+' minutes'
  end			
  def indexer
    count=Status.count
    render :status => 200, :text => count
  end
  protected 
  def check_logs 
    log_file=	File.new(LOG_FILE,'r')
    txt=''
    zone = ActiveSupport::TimeZone.new("Pacific Time (US & Canada)")
    if params[:minutes].nil?
      params[:minutes]='15'
    end
    cutoff_time= params[:minutes].to_i.minutes.ago
    cutoff_time=DateTime.parse(cutoff_time.to_s).in_time_zone(zone)

    while(line=log_file.gets)

      #check whether this is a successful index
      if line.match 'updated'
        #parse the time to see if it was within the last params[:interval] minutes
        timestamp=line.split('[').last.split('\.').first
        this_run=DateTime.parse(timestamp).change(:offset => "-0800")	
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

class Robot < ActiveRecord::Base
  attr_accessible :wf, :process
  
  def status
    puts "wf_#{wf}_#{process}_dt_facet"
     docs = Dor::SearchService.query("wf_#{wf}_#{process}_dt:[NOW-7HOURS-15MINUTES TO NOW]", {:rows => 20, :fl => 'id'})['response']['docs']
     if docs.length >0 
       true
     else
       false
     end
  end
  def status_long
    docs = Dor::SearchService.query("wf_#{wf}_#{process}_dt:[NOW-8HOURS  TO NOW]", {:rows => 20, :fl => 'id'})['response']['docs']
    if docs.length >0 
      true
    else
      false
    end
  end
  def recent_work
    docs = Dor::SearchService.query("wf_#{wf}_#{process}_dt:[NOW-8HOURS  TO NOW]", {:rows => 20, :fl => 'id,dc_title_t,apo_title_facet'})['response']['docs']
  end
end

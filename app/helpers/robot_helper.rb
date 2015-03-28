module RobotHelper
  def render_recent_work docs
    res=''
    docs.each do |doc|
      res += render(:partial => 'item', :locals => {:title => doc['dc_title_si'].first, :druid => doc['id'], :apo_title => doc['apo_title_ssm'] ? doc['apo_title_ssm'] : "Hydrus Object"})
    end
    res.html_safe
  end
end

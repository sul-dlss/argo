module RobotHelper
  def render_recent_work docs
    res=''
    docs.each do |doc|
      res += render(:partial => 'item', :locals => {:title => doc['dc_title_t'].first, :druid => doc['id'], :apo_title => doc['apo_title_facet'] ? doc['apo_title_facet'] : "Hydrus Object"})
    end
    res.html_safe
  end
end

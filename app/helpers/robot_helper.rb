module RobotHelper
  def render_recent_work(docs)
    res = ''
    docs.each do |doc|
      res += render(:partial => 'item', :locals => {:title => doc.title, :druid => doc['id'], :apo_title => doc.apo_title})
    end
    res.html_safe
  end
end

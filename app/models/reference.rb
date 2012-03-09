class Reference

  def self.find(druid)
    Dor::SearchService.query(%{id:"#{druid}"}, :rows => 1).docs.first
  end
  
end

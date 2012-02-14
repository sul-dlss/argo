class Reference

  def self.find(druid)
    Dor::SearchService.query(%{id:"#{druid}"}, :rows => 1).hits.first
  end
  
end

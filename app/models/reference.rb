class Reference

  def self.find(druid)
    resp = Dor::SearchService.gsearch :q => %{id:"#{druid}"}, :rows => 1
    resp['response']['docs'].first
  end
  
end

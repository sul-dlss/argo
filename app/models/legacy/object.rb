class Legacy::Object < Legacy::Base
  
  self.table_name = 'objects'
  has_many :files, :foreign_key => 'druid', :primary_key => 'druid'
  
  def dor_item
    Dor::Item.load_instance("druid:#{self.druid}")
  end
  
end

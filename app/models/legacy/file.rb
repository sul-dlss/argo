class Legacy::File < Legacy::Base
  set_table_name 'files'
  belongs_to :object, :foreign_key => 'druid', :primary_key => 'druid'
  has_one :role, :foreign_key => 'role_id', :primary_key => 'file_role'
  has_one :crop_info, :foreign_key => 'file_id', :primary_key => 'id'
  
  def alternate(role)
    old_role = '%2.2d' % file_role
    new_role = '%2.2d' % role.to_i
    alternate_name = self.file_name.sub(%r{/#{old_role}/},"/#{new_role}/").sub(%r{_#{old_role}_},"_#{new_role}_")
    self.class.find_by_file_name(alternate_name)
  end
  
  def alternates
    old_role = '%2.2d' % file_role
    pattern = self.file_name.gsub(/_/,'!_').sub(%r{/#{old_role}/},"/__/").sub(%r{!_#{old_role}!_},"!___!_")
    self.class.find(:all, :conditions => %{file_name LIKE "#{pattern}" ESCAPE "!"}, :order => 'file_role')
  end
end

class Legacy::File < Legacy::Base
  set_table_name 'files'
  belongs_to :object, :foreign_key => 'druid', :primary_key => 'druid'
  has_one :role, :foreign_key => 'role_id', :primary_key => 'file_role'
  has_one :crop_info, :foreign_key => 'file_id', :primary_key => 'id'
end

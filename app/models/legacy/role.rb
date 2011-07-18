class Legacy::Role < Legacy::Base
  set_table_name 'file_roles'
  has_many :files, :foreign_key => 'file_role', :primary_key => 'role_id'
end

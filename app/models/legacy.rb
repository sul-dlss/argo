module Legacy
  class Base < ActiveRecord::Base
    establish_connection ::Rails.configuration.database_configuration['legacy'][::Rails.env]
    self.abstract_class = true
    instance_variable_set :@columns, []
  end
end

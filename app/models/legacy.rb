module Legacy
  class Base < ActiveRecord::Base
    establish_connection ::Rails.configuration.database_configuration['legacy'][::Rails.env]
  end
end

$config = YAML.load_file(File.join(::Rails.root.to_s, 'config', 'database.yml'))

module Legacy
  class Base < ActiveRecord::Base
    establish_connection $config['legacy'][::Rails.env]
  end
end

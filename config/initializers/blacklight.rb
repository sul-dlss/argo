# frozen_string_literal: true

# Change the order of the load paths so that Blacklight::Document gets loaded first.
# See https://github.com/projectblacklight/blacklight/issues/2346
Blacklight::Engine.config.eager_load_paths = [File.join(Blacklight.root, 'app', 'models', 'concerns')] + Blacklight::Engine.config.eager_load_paths
##
# Configure Blacklight to use POST as the default HTTP method
Blacklight::Configuration.default_values[:http_method] = :post

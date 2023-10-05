# frozen_string_literal: true

# Select the correct item for which you use below.
# If you're not using bundler, remove it completely.
#
# # If we're using a Bundler 1.0 beta
ENV['BUNDLE_GEMFILE'] = File.expand_path('../Gemfile', File.dirname(__FILE__))
require 'bundler/setup'

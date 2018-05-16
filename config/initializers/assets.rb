# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = '1.0'

# Add additional assets to the asset load path
# Rails.application.config.assets.paths << Emoji.images_path

# Precompile additional assets.
# application.js, application.css, and all non-JS/CSS in app/assets folder are already added.
Rails.application.config.assets.precompile += ['registration.css', 'report.css', '*.js', '*.coffee']

Rails.application.config.assets.compress = true

Sprockets::ES6.configuration = { 'modules' => 'amd', 'moduleIds' => true }
# When we upgrade to Sprockets 4, we can ditch sprockets-es6 and config AMD
# in this way:
# https://github.com/rails/sprockets/issues/73#issuecomment-139113466

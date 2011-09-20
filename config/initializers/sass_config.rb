require 'hassle'
Sass::Plugin.options[:template_location] = File.join(Rails.root, 'public/stylesheets/sass')
Rails.configuration.middleware.use(Hassle)

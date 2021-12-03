const { environment } = require('@rails/webpacker')
const webpack = require('webpack')

environment.plugins.prepend(
  'Provide',
  new webpack.ProvidePlugin({
    $: 'jquery',
    jQuery: 'jquery',
    jquery: 'jquery',
    'window.jQuery': 'jquery',
    Popper: ['@popperjs/core', 'default'],
    Rails: ['@rails/ujs'],
    Bloodhound: 'bloodhound-js'
  })
)

module.exports = environment

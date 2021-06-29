const webpack = require('webpack')
const { webpackConfig, merge } = require('@rails/webpacker')
const customConfig = {
    resolve: {
        extensions: ['.scss']
    }
}

webpackConfig.plugins.push(
    new webpack.ProvidePlugin({
        $: 'jquery',
        jQuery: 'jquery',
        jquery: 'jquery',
        'window.jQuery': 'jquery',
        Popper: ['popper.js', 'default'],
        Rails: ['@rails/ujs'],
        Bloodhound: 'bloodhound-js'
    })
)

module.exports = merge(webpackConfig, customConfig)

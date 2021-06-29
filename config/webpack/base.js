const { webpackConfig, merge } = require('@rails/webpacker')
const customConfig = {
    resolve: {
        extensions: ['.scss']
    }
}

module.exports = merge(webpackConfig, customConfig)

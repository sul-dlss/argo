/* eslint no-console:0 */
// This file is automatically compiled by Webpack, along with any other files
// present in this directory. You're encouraged to place your actual application logic in
// a relevant structure within app/javascript and only use these pack files to reference
// that code so it'll be compiled.
//
// To reference this file, add <%= javascript_pack_tag 'application' %> to the appropriate
// layout file, like app/views/layouts/application.html.erb

const images = require.context('../images', true)
const imagePath = (name) => images(name, true)

require('@rails/ujs').start()
global.Rails = Rails

import '@hotwired/turbo-rails'

import 'style/application.scss'

import 'jquery'
require('jquery-ui/themes/base/all')
import 'jquery-ui'
import "bootstrap/dist/js/bootstrap"
import "controllers"

import Argo from 'argo'

import 'blacklight-frontend/app/assets/javascripts/blacklight/blacklight'
import 'modules/blacklight-override'

document.addEventListener("turbo:load", () => { new Argo().initialize() })

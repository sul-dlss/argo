// Entry point for the build script in your package.json

const images = require.context('../images', true)
const imagePath = (name) => images(name, true)

require('@rails/ujs').start()
global.Rails = Rails

import 'jquery'
import 'jquery-ui'
import 'jquery-validation'
import "bootstrap/dist/js/bootstrap"
import "./controllers"
import '@hotwired/turbo-rails'

import Argo from './argo'

import 'blacklight-frontend/app/assets/javascripts/blacklight/blacklight'
import './modules/blacklight-override'

document.addEventListener("turbo:load", () => { new Argo().initialize() })
import * as bootstrap from "bootstrap"

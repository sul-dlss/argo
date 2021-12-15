// Entry point for the build script in your package.json

import 'jquery'
import bootstrap from  "bootstrap/dist/js/bootstrap"
global.bootstrap = bootstrap // Required for Blacklight 7 so it can manage the modals

import 'blacklight-frontend/app/assets/javascripts/blacklight/blacklight'
import "./controllers"

import Argo from './argo'

document.addEventListener("turbo:load", async () => {
  await import('https://cdnjs.cloudflare.com/ajax/libs/free-jqgrid/4.15.5/jquery.jqgrid.src.js')

  // Start argo after free-jqgrid has been loaded
  new Argo().initialize()
})
import '@hotwired/turbo-rails'

// Entry point for the build script in your package.json

import 'jquery'
// These are all jquery plugins that depend on jquery
import './jquery.defaultText'
import './jquery.textarea'
import './spreadsheet' // Note: this library is used to read/write spreadsheet documents, not display
import './modules/button_checker'
import './modules/date_range_query'
import './modules/populate_druids'
import bootstrap from  "bootstrap/dist/js/bootstrap"
import 'blacklight-frontend/app/assets/javascripts/blacklight/blacklight'
import './modules/blacklight-override'
import "./controllers"

import Argo from './argo'

// Override Blacklight 7.22 until https://github.com/projectblacklight/blacklight/pull/2580 is merged
Blacklight.modal.show = (el) => {
  bootstrap.Modal.getOrCreateInstance(el || document.querySelector(Blacklight.modal.modalSelector)).show();
}

document.addEventListener("turbo:load", async () => {
  await import('https://cdnjs.cloudflare.com/ajax/libs/free-jqgrid/4.15.5/jquery.jqgrid.src.js')

  // Start argo after free-jqgrid has been loaded
  new Argo().initialize()
})
import '@hotwired/turbo-rails'

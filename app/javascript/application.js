// Entry point for the build script in your package.json

import 'jquery'
// These are all jquery plugins that depend on jquery
import './jquery.defaultText'
import './jquery.textarea'
import './spreadsheet' // Note: this library is used to read/write spreadsheet documents, not display
import './modules/button_checker'
import './modules/date_range_query'
import './modules/populate_druids'

import "bootstrap/dist/js/bootstrap"


// rails-ujs is required for Blacklight (see https://github.com/projectblacklight/blacklight/pull/2490)
import Rails from '@rails/ujs';
Rails.start();
global.Rails = Rails
import 'blacklight-frontend/app/assets/javascripts/blacklight/blacklight'
import './modules/blacklight-override'
import "./controllers"

import Argo from './argo'

document.addEventListener("turbo:load", async () => {
  await import('https://cdnjs.cloudflare.com/ajax/libs/free-jqgrid/4.15.5/jquery.jqgrid.src.js')

  // Start argo after free-jqgrid has been loaded
  new Argo().initialize()
})

 window.addEventListener('turbo:before-cache', function () {
  // Close any lingering open modal windows
  $('.modal').modal('hide');
  $('.modal-backdrop').remove();
});

import '@hotwired/turbo-rails'

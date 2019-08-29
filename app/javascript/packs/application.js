/* eslint no-console:0 */
// This file is automatically compiled by Webpack, along with any other files
// present in this directory. You're encouraged to place your actual application logic in
// a relevant structure within app/javascript and only use these pack files to reference
// that code so it'll be compiled.
//
// To reference this file, add <%= javascript_pack_tag 'application' %> to the appropriate
// layout file, like app/views/layouts/application.html.erb

//
// Required by Blacklight Hierarchical Facet Plugin
// require blacklight/hierarchy/hierarchy
//
// Required by Argo

import 'style/application.scss'

import 'jquery'
import "jquery-ujs"
require('jquery-ui/themes/base/all')
import 'jquery-ui'
import 'jquery-validation'
import "bootstrap/dist/js/bootstrap"

import 'spreadsheet'

import 'jquery.persistentModal'

import 'modules/apo_form'
import 'modules/button_checker'
import 'modules/datastream_edit'
import 'modules/date_range_query'
import 'modules/index_queue'
import ItemCollection from 'modules/item_collection'
import 'modules/permission_add'
import 'modules/permission_grant'
import 'modules/permission_list'
import 'modules/populate_druids'
import 'modules/sharing'
import Argo from  'argo'

import 'blacklight-frontend/app/assets/javascripts/blacklight/blacklight'

// The Blacklight onLoad event works better than the regular onLoad event if
// turbolinks is enabled.
Blacklight.onLoad(function(){
  $('#spreadsheet-upload-container').argoSpreadsheet()

  // When the user clicks the 'MODS bulk loads' button, a lightbox is opened.
  // The event 'loaded.blacklight.blacklight-modal' is fired just before this
  // Blacklight lightbox is shown.
  $('#blacklight-modal').on('loaded.blacklight.blacklight-modal', function(e){
$('#spreadsheet-upload-container').argoSpreadsheet()
  })
})


Blacklight.onLoad(function() {
  $('[data-behavior="persistent-modal"]').persistentModal()
})


Blacklight.onLoad(function() {
  $('a.disabled[data-check-url]').buttonChecker()
})


/*
   Because we are in a modal dialog we need to use the 'loaded' event
   to trigger the form validation setup.
 */
Blacklight.onLoad(function() {
  $('body').on('loaded.persistent-modal', function() {
    $('#xmlEditForm').datastreamXmlEdit()
  })
})


Blacklight.onLoad(function() {
  $('[data-range-query]').dateRangeQuery()
//  $('[data-datepicker]').datepicker()
})


Blacklight.onLoad(function() {
  $('[data-index-queue-depth-url]').indexQueueDepth()
})


Blacklight.onLoad(function() {
  new ItemCollection().initialize()
})


Blacklight.onLoad(function() {
  $('[data-populate-druids]').populateDruids()
})

Blacklight.onLoad(function() { new Argo().initialize() })

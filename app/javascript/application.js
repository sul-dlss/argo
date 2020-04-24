// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or vendor/assets/javascripts of plugins, if any, can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// the compiled file.
//
// WARNING: THE FIRST BLANK LINE MARKS THE END OF WHAT'S TO BE PROCESSED, ANY BLANK LINE SHOULD
// GO AFTER THE REQUIRES BELOW.
//
//= require jquery3
//= require jquery_ujs
//= require bootstrap
//
// Required by Blacklight
//= require blacklight/blacklight
//
// Not added by Blacklight, but required for tabs to work
//= require bootstrap/tab
//= require bootstrap/button

// Required by Blacklight Hierarchical Facet Plugin
//= require blacklight/hierarchy/hierarchy
//
// Required by Argo
//= require spreadsheet
//= require jquery-ui
//= require jquery.validate
//= require jquery.validate.additional-methods

// These two files come from the jqgrid-jquery-rails gem:
// https://github.com/jhx/gem-jqgrid-jquery-rails/blob/master/vendor/assets/javascripts/jqgrid-jquery-rails.js
//= require i18n/grid.locale-en
//= require jquery.jqGrid.js

//= require jquery.persistentModal
// Stimulus must be loaded before almond because it's a UMD package
//= require stimulus
//= require almond
//= require_directory ./modules
//= require_directory ./controllers
//= require argo

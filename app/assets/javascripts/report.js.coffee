# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

$(document).ready ->
  colModel = report_model.column_model
  colModel[1]['formatter'] = (val, opts, row) -> "<a href='#{val}' target='_blank'>#{val}</a>"

  initialized = false
  $('#report_grid').jqGrid
    url: report_model.data_url
    rownumbers: true
    datatype: 'json'
    pager: 'preport_grid'
    colModel: report_model.column_model
    sortable: true
    jsonReader:
      repeatitems: false
      root: 'rows'
    scroll: 1
    prmNames:
      npage: 'npage'
    viewrecords: true
    recordtext: '{2} records'
    gridComplete: -> 
      unless initialized
        $(window).trigger('resize')
        initialized = true
      
  $('#report_grid').jqGrid 'navGrid', '#preport_grid',
    add:false
    edit:false
    del:false
    search:false
    refresh:true
    
  $('#report_grid').jqGrid 'navButtonAdd', '#preport_grid',
    caption: "Columns"
    title: "Choose Columns"
    buttonicon: 'ui-icon-script'
    onClickButton: -> $('#report_grid').jqGrid('columnChooser')

  $('#report_grid').jqGrid 'navButtonAdd', '#preport_grid',
    caption: "Download"
    title: "Download as CSV"
    buttonicon: 'ui-icon-disk'
    onClickButton: -> 
      visible = $.grep $('#report_grid').jqGrid('getGridParam','colModel'), (col,idx) -> (col.name != 'rn' && !col.hidden)
      field_list = $.map(visible, (col,idx) -> col.name).join(',')
      $("body").append("<iframe src='" + report_model.download_url + "&fields=" + field_list + "' style='display: none;' ></iframe>");

  resized = ->
    
    $('#report_grid').jqGrid('setGridHeight', $(window).innerHeight() - ($('#appliedParams').offset().top + $('#appliedParams').outerHeight()) - 90)
    $('#report_grid').jqGrid('setGridWidth',  $('#appliedParams').outerWidth())

  resize_timeout = null
  $(window).bind 'resize', =>
    if resize_timeout
      clearTimeout(resize_timeout)
    resize_timeout = setTimeout(resized, 200)

  resized()
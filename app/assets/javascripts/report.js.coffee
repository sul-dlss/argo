# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

$(document).ready ->
  colModel = report_model.column_model
  colModel[1]['formatter'] = (val, opts, row) -> "<a href='#{val}' target='_blank'>#{val}</a>"
  
  $('#report_grid').jqGrid
    url: report_model.data_url
    rownumbers: true
    datatype: 'json'
    pager: 'preport_grid'
    colNames: report_model.field_names
    colModel: report_model.column_model
    sortable: true
    jsonReader:
      repeatitems: false
      root: 'rows'
    scroll: 1
    prmNames:
      npage: 'npage'
      
  $('#report_grid').jqGrid 'navGrid', '#preport_grid',
    add:false
    edit:false
    del:false
    search:false
    refresh:true
    
  $('#report_grid').jqGrid 'navButtonAdd', '#preport_grid',
    caption: "Columns"
    title: "Choose Columns"
    onClickButton: -> $('#report_grid').jqGrid('columnChooser')

  resized = ->
    pos = $('#report_grid').offset()
    $('#report_grid').jqGrid('setGridHeight', $(window).height() - pos.top  - 60)
    $('#report_grid').jqGrid('setGridWidth',  $(window).width()  - pos.left - 24)

  resize_timeout = null
  $(window).bind 'resize', =>
    if resize_timeout
      clearTimeout(resize_timeout)
    resize_timeout = setTimeout(resized, 200)
    
  $(window).trigger('resize')
  $('#report_grid').trigger('reloadGrid')
  
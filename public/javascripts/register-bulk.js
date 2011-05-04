$(document).ready(function() {
  var statusImages = { 
    pending: '/images/icons/spinner.gif', 
    complete: '/images/icons/accept.png', 
    error: '/images/icons/cancel.png' 
  };
  $([statusImages.pending, statusImages.complete, statusImages.error]).preload();

  var addRow = function(sIdentifier, sDruid, sLabel) {
    var newId = $('#data').data('nextId') || 0;
    var newRow = { id: newId, status: '', identifier: sIdentifier, druid: sDruid, label: sLabel }
    $('#data').jqGrid('addRowData',newId, newRow, 'last');
    $('#data').data('nextId',newId+1);
  };

  var addIdentifiers = function(identifiers) {
    identifiers.map(function(newId) {
      if (newId.trim() != '') {
        var params = newId.split('|');
        addRow(params[0],params[1]||'',params[2]||'');
      }
    })
  }
  
  var statusRenderer = function(val, opts, rowObj) {
    if (val != '') {
      return '<image src="'+statusImages[val]+'"/>';
    } else {
      return val;
    }
  }
  
  var addToolbarButton = function(icon,action,title) {
    var icons = $('#icons').append('<li class="ui-state-default ui-corner-all" title="'+title+'"><span class="ui-icon ui-icon-'+icon+' action-'+action+'"></span></li>')
    return $('.action-'+action,icons);
  }

  $(window).bind('resize', function(e) {
    $('#data').setGridWidth($(window).width() - 20,true).setGridHeight($(window).height() - ($('#header').outerHeight() + 100));
  });
  
  $('#data').jqGrid({
    datatype: "local",
    data: [],
    colModel: [
      {label:' ',name:'status',index:'status',width:18,sortable:false,formatter:statusRenderer},
      {label:'Identifier',name:'identifier',index:'identifier',width:150,editable:true},
      {label:'DRUID',name:'druid',index:'druid',width:150,editable:true},
      {label:'Label',name:'label',index:'label', width:($(window).width() - 378),editable:true }
    ],
    viewrecords: true,
    loadonce: true,
    cellsubmit: 'clientArray',
    caption: "Register DOR Items",
    cellEdit: true,
    multiselect: true,
    toolbar: [true, "top"]
  });
  $(window).trigger('resize')
  $('#t_data').html('<ul id="icons"/>')
  $('#icons li').
    live('mouseover', function() { $(this).addClass('ui-state-hover') }).
    live('mouseout', function() { $(this).removeClass('ui-state-hover') });
  
  addToolbarButton('comment','edit-tags','Edit Tags').click(function() {
    $('#tag_dialog').dialog('open');
  });

  addToolbarButton('plus','add','Add Row').click(function() {
    addRow('','','');
  });
  
  addToolbarButton('minus','delete','Delete Selected Rows').click(function() {
    var selection = $('#data').jqGrid('getGridParam','selarrrow');
    for (var i = selection.length-1; i >= 0; i--) {
      $('#data').jqGrid('delRowData',selection[i]);
    }
  });
  
  addToolbarButton('script','add-multiple','Add Multiple Identifiers').click(function() {
    $('#ids_dialog').dialog('open');
  });
  
  addToolbarButton('transfer-e-w','register','Register Objects').click(function() {
    var rc = new DorRegistration();
    rc.registerAll();
  });
  
  $('#t_data').append($('#fields'))
  
  $.defaultText({ css: 'default-text' });
  $('#fields select option:first-child').attr('disabled',true)
  
  $('#tag_dialog').dialog({ 
    autoOpen: false,
    buttons: { "Ok": function() { $(this).dialog("close"); } },
    title: 'Tags'
  });
  
  $('#ids_dialog').dialog({ 
    autoOpen: false,
    buttons: { 
      "Ok": function() { 
        addIdentifiers($('#id_list').val().trim().split('\n'))
        $(this).dialog('close');
        $('#id_list').val('');
      },
      "Cancel": function() { 
        $(this).dialog("close");
        $('#id_list').val('');
      } 
    },
    title: 'Identifiers'
  });

  $('#specify').dialog({
    autoOpen: false,
    buttons: { "Ok": function() { $(this).dialog("close"); } },
    title: 'Error',
    resizable: false
  });
});

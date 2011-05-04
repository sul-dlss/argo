
var gridContext = function() {
  var druidFormatter = function(val, opts, rowObj) {
    if (val.trim() != '') {
      var href = dor_path + "objects/druid:" + val.trim();
      return '<a href="'+href+'" title="'+val+'" target="_blank">'+val+'</a>';
    } else {
      return val;
    }
  };

  var statusFormatter = function(val, opts, rowObj) {
    if (val in gridContext.statusImages) {
      return '<image src="'+gridContext.statusImages[val]+'" title="'+val+'"/>';
    } else {
      return ' ';
    }
  };

  return({
    statusImages: { 
      pending: '/images/icons/spinner.gif', 
      complete: '/images/icons/accept.png', 
      error: '/images/icons/cancel.png' 
    },

    toggleEditing: function(edit) {
      $('#data').jqGrid('setColProp','identifier',{ editable: edit });
      $('#data').jqGrid('setColProp','druid',{ editable: edit, formatter: edit ? null : druidFormatter });
      $('#data').jqGrid('setColProp','label',{ editable: edit });
      $('#data').trigger('reloadGrid');
    },

    addRow: function(sIdentifier, sDruid, sLabel) {
      var newId = $('#data').data('nextId') || 0;
      var newRow = { id: newId, status: '', identifier: sIdentifier, druid: sDruid, label: sLabel }
      $('#data').jqGrid('addRowData',newId, newRow, 'last');
      $('#data').data('nextId',newId+1);
    },

    addIdentifiers: function(identifiers) {
      identifiers.map(function(newId) {
        if (newId.trim() != '') {
          var params = newId.split('|');
          gridContext.addRow(params[0],params[1]||'',params[2]||'');
        }
      })
    },

    reset: function() {
      $('#project').val('');
      $('#apo_id').val('');
      $('#id_source').val('');
      $('#tag_list').val('');
      $('#data').jqGrid('clearGridData');
      gridContext.toggleEditing(true);
      $.defaultText();
    },

    addToolbarButton: function(icon,action,title) {
      var icons = $('#icons').append('<li class="ui-state-default ui-corner-all" title="'+title+'"><span class="ui-icon ui-icon-'+icon+' action-'+action+'"></span></li>')
      return $('.action-'+action,icons);
    },

    initializeContext: function() {
      $([this.statusImages.pending, this.statusImages.complete, this.statusImages.error]).preload();
      $.defaultText({ css: 'default-text' });
      $(window).bind('resize', function(e) {
        $('#data').setGridWidth($(window).attr('innerWidth') - 20,true).setGridHeight($(window).attr('innerHeight') - ($('#header').outerHeight() + 100));
      });
      return(this);
    },

    initializeGrid: function() {
      $('#data').jqGrid({
        data: [],
        datatype: "local",
        caption: "Register DOR Items",
        cellEdit: true,
        cellsubmit: 'clientArray',
        colModel: [
          {label:' ',name:'status',index:'status',width:18,sortable:false,formatter: statusFormatter },
          {label:'Identifier',name:'identifier',index:'identifier',width:150,editable:true},
          {label:'DRUID',name:'druid',index:'druid',width:150,editable:true},
          {label:'Label',name:'label',index:'label', width:($(window).attr('innerWidth') - 378),editable:true }
        ],
        loadonce: true,
        multiselect: true,
        toolbar: [true, "top"],
        viewrecords: true
      });
      $(window).trigger('resize')
      $('#t_data').html('<ul id="icons"/>')
      $('#icons li').
        live('mouseover', function() { $(this).addClass('ui-state-hover') }).
        live('mouseout', function() { $(this).removeClass('ui-state-hover') });

      return(this);
    },

    initializeToolbar: function() {
      this.addToolbarButton('comment','edit-tags','Edit Tags').click(function() {
        $('#tag_dialog').dialog('open');
      });

      this.addToolbarButton('plus','add','Add Row').click(function() {
        gridContext.addRow('','','');
      });

      this.addToolbarButton('minus','delete','Delete Selected Rows').click(function() {
        var selection = $('#data').jqGrid('getGridParam','selarrrow');
        for (var i = selection.length-1; i >= 0; i--) {
          $('#data').jqGrid('delRowData',selection[i]);
        }
      });

      this.addToolbarButton('arrowrefresh-1-w','clear','Reset Grid').click(function() {
        if (window.confirm('Are you sure you want to clear the grid?')) {
          gridContext.reset();
        }
      });

      this.addToolbarButton('script','add-multiple','Add Multiple Identifiers').click(function() {
        $('#ids_dialog').dialog('open');
      });

      this.addToolbarButton('transfer-e-w','register','Register Objects').click(function() {
        gridContext.toggleEditing(false);
        var rc = new DorRegistration();
        rc.registerAll();
      });

      $('#t_data').append($('#fields'));
      return(this);
    },
    
    initializeDialogs: function() {
      $('#tag_dialog').dialog({ 
        autoOpen: false,
        buttons: { "Ok": function() { $(this).dialog("close"); } },
        title: 'Tags'
      });

      $('#ids_dialog').dialog({ 
        autoOpen: false,
        buttons: { 
          "Ok": function() { 
            gridContext.addIdentifiers($('#id_list').val().trim().split('\n'))
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
      return(this);
    },

    initialize: function() {
      this.initializeContext().initializeDialogs().
        initializeGrid().initializeToolbar();
    }
  });
}();

$(document).ready(function() {
  gridContext.initialize();
});
  

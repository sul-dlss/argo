
var gridContext = function() {
  var rc = new DorRegistration();
    
  var druidFormatter = function(val, opts, rowObj) {
    if (val.trim() != '') {
      var href = dor_path + "objects/druid:" + val.trim();
      return '<a href="'+href+'" title="'+val+'" target="_blank">'+val+'</a>';
    } else {
      return val;
    }
  };

  var statusFormatter = function(val, opts, rowObj) {
    if (val in $t.statusImages) {
      var result = '<image src="'+$t.statusImages[val]+'" title="'+(rowObj.error||val)+'"/>';
      if (rowObj.druid) {
        var href = dor_path + "objects/druid:" + rowObj.druid;
        return '<a href="'+href+'" target="_blank">'+result+'</a>';
      }
      return(result)
    } else {
      return ' ';
    }
  };

  var $t = {
    statusImages: { 
      pending: '../images/icons/spinner.gif', 
      success: '../images/icons/accept.png', 
      error: '../images/icons/exclamation.png',
      abort: '../images/icons/cancel.png'
    },

    toggleEditing: function(edit) {
      this.stopEditing(true);
      $('#data').jqGrid('setColProp','source_id',{ editable: edit });
      $('#data').jqGrid('setColProp','metadata_id',{ editable: edit });
      $('#data').jqGrid('setColProp','druid',{ editable: edit }); //, formatter: edit ? null : druidFormatter });
      $('#data').jqGrid('setColProp','label',{ editable: edit });
      $('.action-lock').closest('li').toggle(edit);
      $('.action-unlock').closest('li').toggle(!edit);
    },

    stopEditing: function(autoSave) {
      var cells = $('#data').jqGrid('getGridParam','savedRow');
      if (cells.length > 0) {
        var method = autoSave ? 'saveCell' : 'restoreCell';
        $('#data').jqGrid(method,cells[0].id,cells[0].ic);
      }
    },
    
    addRow: function(column_data) {
      var newId = $('#data').data('nextId') || 0;
      var newRow = { id: newId };
      var columns = $('#data').jqGrid('getGridParam','colModel');
      
      for (var i = 2; i < columns.length; i++) {
        newRow[columns[i].name] = column_data[i-2] || '';
      }
      $('#data').jqGrid('addRowData',newId, newRow, 'last');
      $('#data').data('nextId',newId+1);
    },

    addIdentifiers: function(identifiers) {
      identifiers.map(function(newId) {
        if (newId.trim() != '') {
          var params = newId.split('\t');
          $t.addRow(params);
        }
      })
    },

    reset: function() {
      $('#project').val('');
      $('#apo_id').val('');
      $('#id_source').val('');
      $('#tag_list').val('');
      $('#data').jqGrid('clearGridData');
      $t.toggleEditing(true);
      $.defaultText();
    },

    addToolbarButton: function(icon,action,title) {
      var icons = $('#icons').append('<li class="ui-state-default ui-corner-all" title="'+title+'"><span class="ui-icon ui-icon-'+icon+' action-'+action+'"></span></li>')
      return $('.action-'+action,icons);
    },

    initializeContext: function() {
      $([this.statusImages.pending, this.statusImages.success, this.statusImages.error, this.statusImages.abort]).preload();
      $.defaultText({ css: 'default-text' });
      $(window).bind('resize', function(e) {
        $('#data').setGridWidth($('#container').width(),true).setGridHeight($(window).attr('innerHeight') - ($('#header').outerHeight() + 100));
        // Make up for width calculation error in jqgrid header code.
        $('#t_data').width($('#gview_data .ui-jqgrid-titlebar').width());
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
          {label:'Metadata ID',name:'metadata_id',index:'metadata_id',width:150,editable:true},
          {label:'Source ID',name:'source_id',index:'source_id',width:150,editable:true},
          {label:'DRUID',name:'druid',index:'druid',width:150,editable:true},
          {label:'Label',name:'label',index:'label', width:($(window).attr('innerWidth') - 498),editable:true },
          {label:'Error',name:'error',index:'error',hidden:true}
        ],
        loadonce: true,
        multiselect: true,
        scroll: true,
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
      this.addToolbarButton('note','pdf','Generate Tracking Sheets').click(function() {
        $t.stopEditing(true);
        rc.getTrackingSheet();
      });
      
      this.addToolbarButton('locked','lock','Lock Grid').click(function() {
        $t.toggleEditing(false);
      });
      
      this.addToolbarButton('unlocked','unlock','Unlock Grid').click(function() {
        $t.toggleEditing(true);
      }).closest('li').toggle(false);

      this.addToolbarButton('comment','edit-tags','Edit Tags').click(function() {
        $('#tag_dialog').dialog('open');
      });

      this.addToolbarButton('plus','add','Add Row').click(function() {
        $t.addRow([]);
      });

      this.addToolbarButton('minus','delete','Delete Selected Rows').click(function() {
        var selection = $('#data').jqGrid('getGridParam','selarrrow');
        for (var i = selection.length-1; i >= 0; i--) {
          $('#data').jqGrid('delRowData',selection[i]);
        }
      });

      this.addToolbarButton('arrowrefresh-1-w','clear','Reset Grid').click(function() {
        if (window.confirm('Are you sure you want to clear the grid?')) {
          $t.reset();
        }
      });

      this.addToolbarButton('clipboard','add-multiple','Add Multiple Identifiers').click(function() {
        $('#ids_dialog').dialog('open');
      });

      this.addToolbarButton('transfer-e-w','register','Register Objects').click(function() {
        $t.toggleEditing(false);
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
            $t.addIdentifiers($('#id_list').val().trim().split('\n'))
            $(this).dialog('close');
            $('#id_list').val('');
          },
          "Cancel": function() { 
            $(this).dialog("close");
            $('#id_list').val('');
          } 
        },
        title: 'Identifiers',
        width: window.innerWidth / 2,
        height: window.innerHeight / 2
      });

      $('#specify').dialog({
        autoOpen: false,
        buttons: { "Ok": function() { $(this).dialog("close"); } },
        title: 'Error',
        resizable: false
      });
      
      $('#progress_dialog').dialog({
        autoOpen: false,
        height: 50,
        title: 'Progress',
        resizable: false
      });
      $('#progress').progressbar();
      
      return(this);
    },

    initialize: function() {
      this.initializeContext().initializeDialogs().
        initializeGrid().initializeToolbar();
    }
  };
  return($t);
}();

$(document).ready(function() {
  gridContext.initialize();
});
  

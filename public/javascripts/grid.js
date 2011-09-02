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

  var createRegistrationContext = function() {
    var progressStep = 1;
    var currentStep = 0;
    return new DorRegistration({
      setStatus : function(data, status) {
        data.status = status;
        return $('#data').jqGrid('setRowData', data.id, data);
      },
      getDataIds : function() {
        return $('#data').jqGrid('getDataIDs');
      },
      getData : function(rowid) {
        return $('#data').jqGrid('getRowData',rowid);
      },
      progress : function(init) {
        if (init) {
          var numItems = $('#data').jqGrid('getDataIDs').length;
          progressStep = 100 / numItems;
          currentStep = 0;
          $('#progress').progressbar('option','value',currentStep);
          $('#progress_dialog').dialog('option','title','Registering '+numItems+' items')
          $('#progress_dialog').dialog('open');
        } else {
          currentStep += progressStep;
          $('#progress').progressbar('option','value',currentStep);
          if (currentStep >= 99.999) { $('#progress_dialog').dialog('close'); }
        }
      },
      displayRequirements : function() {
        $('#specify').dialog('open');
      }
    });
  };
  
  var $t = {
    rc: createRegistrationContext(),
    statusImages: {},
    
    resizeIdList: function() {
      $('#id_list').animate({
        'top': $('#gbox_data .ui-jqgrid-hdiv').position().top + 3, 
        'left': 3,
        'width': $('#gbox_data .ui-jqgrid-bdiv').width() - 4, 
        'height' : $('#gbox_data .ui-jqgrid-hdiv').height() + $('#gbox_data .ui-jqgrid-bdiv').height() - 4
      }, 0);
    },
    
    toggleText: function(textMode) {
      if (textMode) {
        $t.stopEditing(true);
        $t.gridToText();
        $t.resizeIdList();
        $('#id_list').show();
      } else {
        $t.textToGrid();
        $('#id_list').hide();
      }
      $('#icons button').button('option', 'disabled', textMode);
    },
    
    toggleEditing: function(edit) {
      this.stopEditing(true);
      $('#data').jqGrid('setColProp','source_id',{ editable: edit });
      $('#data').jqGrid('setColProp','metadata_id',{ editable: edit });
      $('#data').jqGrid('setColProp','druid',{ editable: edit }); //, formatter: edit ? null : druidFormatter });
      $('#data').jqGrid('setColProp','label',{ editable: edit });

      $('#icons *').button('option', 'disabled', !edit);
      $('#icons .enabled-grid-locked').button('option', 'disabled', false);
      $('.action-lock').toggle(edit);
      $('.action-unlock').toggle(!edit);
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

    textToGrid: function() {
      $('#data').jqGrid('clearGridData');
      $('#data').data('nextId',0);
      var textData = $('#id_list').val().replace(/^\t*\n$/,'');
      $t.addIdentifiers(textData.split('\n'));
    },
    
    gridToText: function() {
      var text = '';
      var gridData = $('#data').jqGrid('getRowData');
      for (var i = 0; i < gridData.length; i++) {
        var rowData = gridData[i];
        text += [rowData.metadata_id, rowData.source_id, rowData.druid, rowData.label].join("\t") + "\n"
      }
      $('#id_list').val(text);
    },
    
    reset: function() {
      $t.rc = createRegistrationContext();

      $('#data').jqGrid('clearGridData');
      $t.toggleEditing(true);
      $.defaultText();
    },

    addToolbarButton: function(icon,action,title) {
      var parent = $('#icons span[class="button-group"]:last');
      if (parent.length == 0) {
        parent = $('#icons');
      }
      var parent = parent.append('<button class="action-'+action+'">'+title+'</button>');
      var button = $('.action-'+action,parent);
      button.button({ icons : { primary: 'ui-icon-'+icon }, text : true });
      return button;
    },

    initializeContext: function() {
      $t.statusImages = { 
        queued: pathTo('/images/icons/queued.png'), 
        pending: pathTo('/images/icons/spinner.gif'), 
        success: pathTo('/images/icons/accept.png'), 
        error: pathTo('/images/icons/exclamation.png'),
        abort: pathTo('/images/icons/cancel.png'),
        preloadImages: function() {
          $([this.queued, this.pending, this.success, this.error, this.abort]).preload();
        }
      }
      this.statusImages.preloadImages();

      $.defaultText({ css: 'default-text' });
      $(window).bind('resize', function(e) {
        var tabDivHeight = $(window).attr('innerHeight') - ($('#header').height() + 30);
        $('#tabs').height(tabDivHeight);
        var tabHeadHeight = $('#tabs .ui-tabs-nav').height();
        $('#id_list').height(tabDivHeight - tabHeadHeight);
        $('#data').setGridWidth($('#container').width(),true).setGridHeight($(window).attr('innerHeight') - ($('#header').outerHeight() + 100));
        // Make up for width calculation error in jqgrid header code.
        $('#t_data').width($('#gview_data .ui-jqgrid-titlebar').width());
        if ($('#id_list').css('display') != 'none') {
          $t.resizeIdList();
        }
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
          {label:'Label',name:'label',index:'label', width:($('#content').width() - 468),editable:true },
          {label:'Error',name:'error',index:'error',hidden:true}
        ],
        hidegrid: false,
        loadonce: true,
        multiselect: true,
        scroll: true,
        toolbar: [true, "top"],
        viewrecords: true
      });
      $(window).trigger('resize')
      $('#t_data').html('<div id="icons"/>')

      return(this);
    },

    initializeToolbar: function() {
      $('#icons').append('<span class="button-group"></span>');
      
      this.addToolbarButton('locked','lock','Lock').click(function() {
        $t.toggleEditing(false);
      });

      this.addToolbarButton('unlocked','unlock','Unlock').click(function() {
        $t.toggleEditing(true);
      }).addClass('enabled-grid-locked').hide();

      $('#icons').append('<span class="button-group"></span>');

      this.addToolbarButton('plus','add','Add Row').click(function() {
        $t.addRow([]);
      });

      this.addToolbarButton('minus','delete','Delete Rows').click(function() {
        var selection = $('#data').jqGrid('getGridParam','selarrrow');
        for (var i = selection.length-1; i >= 0; i--) {
          $('#data').jqGrid('delRowData',selection[i]);
        }
      });

      this.addToolbarButton('arrowrefresh-1-w','clear','Reset').click(function() {
        $('#reset_dialog').dialog('open');
      });

      $('#icons').append('<span class="button-group"></span>');

      this.addToolbarButton('tag','edit-properties','Properties').click(function() {
        $('#properties_dialog').dialog('open');
      });

      this.addToolbarButton('transfer-e-w','register','Register').click(function() {
        $t.toggleEditing(false);
        $t.rc.registerAll();
      }).addClass('enabled-grid-locked');
      
      this.addToolbarButton('note','pdf','Tracking Sheets').click(function() {
        $t.stopEditing(true);
        $t.rc.getTrackingSheet($('#data').getCol('druid'));
      }).addClass('enabled-grid-locked');
      
      $('#icons').append('<span class="button-group" id="view-toggle"/>');
      $('#view-toggle').append('<input type="radio" id="grid-view" name="view" checked="checked"/><label for="grid-view">Grid</label></span>');
      $('#view-toggle').append('<input type="radio" id="text-view" name="view" /><label for="text-view">Text</label></span>');
      $('#view-toggle').buttonset();
      
      $('#view-toggle input').change(function(e) { 
        $t.toggleText(e.target.id == 'text-view');
      });
      
      return(this);
    },
    
    initializeDialogs: function() {
      $('#properties_dialog').dialog({
        autoOpen: false,
        open: function() {
          $('#project').val($t.rc.projectName);
          $('#apo_id').val($t.rc.apoId);
          $('#workflow_id').val($t.rc.workflowId);
          $('#mdform_id').val($t.rc.mdFormId);
          $('#id_source').val($t.rc.metadataSource);
          $('#tag_list').val($t.rc.tagList);
        },
        buttons: { 
          "Ok": function() { 
            $t.rc.projectName = $('#project').val();
            $t.rc.apoId = $('#apo_id').val();
            $t.rc.workflowId = $('#workflow_id').val();
            $t.rc.mdFormId = $('#mdform_id').val();
            $t.rc.metadataSource = $('#id_source').val();
            $t.rc.tagList = $('#tag_list').val();
            $(this).dialog("close");
          },
          "Cancel": function() { $(this).dialog("close"); }
        },
        title: 'Registration Properties'
      });

      $('#project').autocomplete({
        source: pathTo('/registration/suggest_project'),
        minLength: 0
      });
      
      // Update Workflow and Form lists when APO changes
      $('#apo_id').change(function(e) {
        $.ajax({
          type: 'GET',
          url: pathTo('/registration/workflow_list'),
          dataType: 'json',
          data: { apo_id: $('#apo_id').val() },
          success: function(response,status,xhr) { 
            if (response) {
              var optionsHtml = response.map(function(v) { return '<option value="'+v+'">'+v+'</option>' }).join('');
              $('#workflow_id').html(optionsHtml);
            }
          }
        })
        
        $.ajax({
          type: 'GET',
          url: pathTo('/registration/form_list'),
          dataType: 'json',
          data: { apo_id: $('#apo_id').val() },
          success: function(response,status,xhr) { 
            if (response) {
              var optionsHtml = '<option value="">None</option>'
              optionsHtml += response.map(function(v) { return '<option value="'+v[0]+'">'+v[1]+'</option>' }).join('');
              $('#mdform_id').html(optionsHtml);
            }
          }
        })
      });
      
      $('#specify').dialog({
        autoOpen: false,
        buttons: { "Ok": function() { $(this).dialog("close"); } },
        modal: true,
        height: 140,
        title: 'Error',
        resizable: false
      });
      
      $('#reset_dialog').dialog({
        autoOpen: false,
        buttons: { 
          "Ok": function() { 
            $t.reset(); 
            $(this).dialog("close"); 
            $('#properties_dialog').dialog('open');
          },
          "Cancel": function() { $(this).dialog("close"); }
        },
        modal: true,
        height: 140,
        title: 'Confirm',
        resizable: false
      });
      
      $('#progress_dialog').dialog({
        autoOpen: false,
        height: 56,
        title: 'Progress',
        resizable: false
      });
      $('#progress').progressbar();

      $('#id_list').tabby();
      
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
  $('#properties_dialog').dialog('open');
});
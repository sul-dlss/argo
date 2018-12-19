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
    if (val in $t.statusIcons) {
      var result = '<span class="' + $t.statusIcons[val] + '" title="' +
        (rowObj.error||val)+'" aria-hidden="true"></span>';
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
      displayRequirements : function(text) {
        $('#specify p').html(text);
        $('#specify').dialog('open');
      }
    });
  };

  var $t = {
    rc: createRegistrationContext(),
    statusIcons: {},

    processValue: function(cellname, value) {
      // Strip leading and trailing punctuation from everything but label
      if (value) {
        if (cellname == 'label')
          return value.trim();
        else
          return value.replace(/(^[^a-zA-Z0-9]+|[^a-zA-Z0-9]+$)/g,"");
      } else {
        return ''
      }
    },

    resizeGrid: function() {
      var tabDivHeight = $(window).attr('innerHeight') - ($('#header').height() + 30);
      $('#tabs').height(tabDivHeight);
      var tabHeadHeight = $('#tabs .ui-tabs-nav').height();
      $('#id_list').height(tabDivHeight - tabHeadHeight);
      $('#data').setGridWidth($('#main-container').width(),true).setGridHeight($(window).attr('innerHeight') - ($('#header').outerHeight() + 100 + $('#properties').outerHeight()));
      // Make up for width calculation error in jqgrid header code.
      $('#t_data').width($('#gview_data .ui-jqgrid-titlebar').width());
      if ($('#id_list').css('display') != 'none') {
        $t.resizeIdList();
      }
    },

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

      //$('#icons *').button('option', 'disabled', !edit);
      //$('#icons .enabled-grid-locked').button('option', 'disabled', false);
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
        var value = $t.processValue(columns[i].name, column_data[i-2]);
        newRow[columns[i].name] = value;
      }
      $('#data').jqGrid('addRowData',newId, newRow, 'last');
      $('#data').jqGrid('setRowData',newId, newRow);
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
      $t.formatDruids();
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

    allValid: function() {
      var result = $('#properties .invalid').length == 0 && $('#data .invalid').length == 0
      return result
    },

    formatDruids: function(index) {
      var rowCount = $('#data').jqGrid('getGridParam','reccount');
      var checkRow = function(i) {
        var rowData = $('#data').jqGrid('getRowData',i);
        rowData.druid = rowData.druid.trim().replace(/^.+:/,'')
        $('#data').jqGrid('setRowData',i,rowData);
      }
      if (typeof index == 'undefined') {
        for (var i = 0; i < rowCount; i++) {
          checkRow(i)
        }
      } else {
        checkRow(index)
      }
    },

    initializeContext: function() {
      $t.statusIcons = {
        queued:  'registration-status glyphicon glyphicon-forward',
        pending: 'registration-status glyphicon glyphicon-refresh ' +
          'glyphicon-spin',
        success: 'registration-status glyphicon glyphicon-ok-sign',
        error:   'registration-status glyphicon glyphicon-exclamation-sign',
        abort: 'registration-status glyphicon glyphicon-remove-sign'
      };
      $.defaultText({ css: 'default-text' });
      $(window).bind('resize', function(e) {
        $t.resizeGrid();
      });
      return(this);
    },

    initializeGrid: function() {
      var sourceIdFormatter = function(val,opts,rowObject) {
        var cell = $('#data tr#'+opts.rowId+' td:eq('+opts.pos+')')
        if (val.length>0 && (val.match(/^\s*$/) || val.match(/^.+:.+$/))) {
          cell.removeClass('invalidDisplay')
        } else {
          cell.addClass('invalidDisplay')
        }
        return val
      }
      var metadataIdFormatter = function(val,opts,rowObject) {
        var cell = $('#data tr#'+opts.rowId+' td:eq('+opts.pos+')')
        if (val.length>0 && val.indexOf(':')>=0) {
          cell.addClass('invalidDisplay')
        } else {
          cell.removeClass('invalidDisplay')
        }
        return val
      }

      var druidFormatter = function(val,opts,rowObject) {
        var cell = $('#data tr#'+opts.rowId+' td:eq('+opts.pos+')')
        var newVal = val.replace(/^.+:/,'')
        if (newVal.match(/^([a-z]{2}[0-9]{3}[a-z]{2}[0-9]{4})?$/)) {
          cell.removeClass('invalidDisplay')
        } else {
          cell.addClass('invalidDisplay')
        }
        return newVal
      }
      var labelFormatter = function(val,opts,rowObject) {
        var cell = $('#data tr#'+opts.rowId+' td:eq('+opts.pos+')')
        if(val.trim().length>0){
          cell.removeClass('invalidDisplay')
        } else {
          cell.addClass('invalidDisplay')
        }
        return val;
      }

      $('#data').jqGrid({
        data: [],
        datatype: "local",
        caption: "Register DOR Items",
        cellEdit: true,
        autoencode: true,
        cellsubmit: 'clientArray',
        colModel: [
          {label:' ',name:'status',index:'status',width:18,sortable:false,formatter: statusFormatter },
          {label:'Metadata ID',name:'metadata_id',index:'metadata_id',width:150,editable:true,formatter:metadataIdFormatter},
          {label:'Source ID',name:'source_id',index:'source_id',width:150,editable:true,formatter:sourceIdFormatter},
          {label:'DRUID',name:'druid',index:'druid',width:150,editable:true,formatter:druidFormatter},
          {label:'Label',name:'label',index:'label', width:($('#dynamic').width() - 468),editable:true,formatter:labelFormatter },
          {label:'Error',name:'error',index:'error',hidden:true}
        ],
        hidegrid: false,
        loadonce: true,
        multiselect: true,
        scroll: true,
        toolbar: [true, "top"],
        viewrecords: true,
        beforeSaveCell: function(rowid, cellname, value, row, col) {
          return $t.processValue(cellname, value);
        }
      });
      $('#gbox_data').addClass('col-md-12');
      $(window).trigger('resize')
      $('#t_data').html('<div id="icons"/>')
      $('#properties').show().insertBefore($('#dynamic .ui-userdata'))

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

      this.addToolbarButton('transfer-e-w','register','Register').click(function() {
        var cells = $('#data').jqGrid('getGridParam','savedRow');
        if (cells.length > 0) {
          $('#editing_dialog').dialog('open')
          return;
        }
        else{
          if ($t.allValid()) {
            $t.toggleEditing(false);
            $t.rc.registerAll();
          } else {
            $('#invalid_dialog').dialog('open')
          }
        }
      }).addClass('enabled-grid-locked');

      this.addToolbarButton('note','pdf','Tracking Sheets').click(function() {
        $t.stopEditing(true);
        $t.rc.getTrackingSheet($('#data').getCol('druid'));
      }).addClass('enabled-grid-locked');

      $('#icons').append('<span class="button-group" id="view-toggle"/>');
      $('#view-toggle').append('<input type="radio" id="grid-view" name="view" checked="checked"/><label for="grid-view">Grid</label></span>');
      $('#view-toggle').append('<input type="radio" id="text-view" name="view" /><label for="text-view">Text</label></span>');
      $('#view-toggle').controlgroup();

      $('#view-toggle input').checkboxradio({ icon: false }).change(function(e) {
        $t.toggleText(e.target.id == 'text-view');
      });

      return(this);
    },

    setTags: function() {
      var tags = $('#properties .tag-field').map(function(index,elem) {
        var field = $(elem);
        var value = field.val();
        if (field.attr('disabled') || value == null || value.trim() == '') {
          return null
        } else {
          var prefix = field.data('tagname')
          if (prefix) {
            return prefix + ' : ' + value
          } else {
            return value
          }
        }
      })
      tags = $.map(tags, function(e) { return e })
      $t.rc.tagList = tags.join("\n").trim();
    },

    initializeCallbacks: function() {
      $('#properties input,#properties select').change(function(evt) {
        var sender = $(evt.target)
        var prop = sender.data('rcparam')
        if (prop) {
          $t.rc[prop] = sender.val();
        }
        return true
      });

      $('#properties input.free.tag-field').change(function(evt) {
        var sender = $(evt.target)
        var value = sender.val().trim().split(/\s*:\s*/)
        sender.val(value.join(' : '))
        if ((value.length == 1 && value[0] != '') || (value.length > 1 && $.grep(value, function(x) { return(x == '') }).length > 0)) {
          sender.addClass('invalid')
        } else {
          sender.removeClass('invalid')
        }
        $t.setTags();
        return(true);
      });

      $('#properties input.ui-autocomplete-input').blur(function(evt) {
        $t.setTags();
        $(evt.target).change();
      })

      $('#properties select.tag-field').change($t.setTags)

      var disable = function(elem,bool) {
        var target = $(elem)
        if (target.attr('disabled') != bool) {
          target.attr('disabled',bool)
          if (bool) {
            var param = target.data('rcparam');
            if (param) { $t.rc.setDefault(param); }
          } else {
            target.change()
          }
        }
        return(true)
      }

      $('#object_type').change(function(evt) {
        var sender = evt.target
        var valid_controls = {
          'item'       : ["object_type", "apo_id", "rights", "id_source", "workflow_id", "content_type", "project", "registered_by", "tags_0", "tags_1", "tags_2", "tags_3", "tags_4", "tags_5", "tags_6", "tags_7", "collection"],
          'set'        : ["object_type", "apo_id", "rights", "id_source", "project", "registered_by", "tags_0", "tags_1", "tags_2", "tags_3", "tags_4", "tags_5", "tags_6", "tags_7"],
          'collection' : ["object_type", "apo_id", "rights", "id_source", "project", "registered_by", "tags_0", "tags_1", "tags_2", "tags_3", "tags_4", "tags_5", "tags_6", "tags_7"],
          'adminPolicy': ["object_type", "registered_by"],
          'workflow'   : ["object_type", "registered_by"]
        }
        var current_type = $('#object_type').val();
        var enable = valid_controls[current_type];
        $('#properties input,#properties select').each( function(index,elem) {
          if (elem.id != sender.id) {
            disable(elem, enable.indexOf(elem.id) == -1)
          }
        })
        $t.setTags();
        return true
      })

      return(this);
    },

    initializeDialogs: function() {
      $('#project').autocomplete({
        source: pathTo('/registration/suggest_project'),
        minLength: 0,
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
          url: pathTo('/registration/collection_list'),
          dataType: 'json',
          data: { apo_id: $('#apo_id').val() },
          success: function(response,status,xhr) {
            if (response) {
              var optionsHtml='';
              for (var entry in response)
              {
                if(response.hasOwnProperty(entry))
                {
                  if(response[entry].indexOf('default')!=-1 || response[entry].indexOf('Assembly')!=-1)
                  {
                    optionsHtml+='<option selected="selected" value="'+entry+'">'+response[entry]+'</option>';
                  }
                  else
                  {
                    optionsHtml+='<option value="'+entry+'">'+response[entry]+'</option>';
                  }
                }
              }
              $('#collection').html(optionsHtml);
            }
          }
        })

        $.ajax({
          type: 'GET',
          url: pathTo('/registration/rights_list'),
          dataType: 'json',
          data: { apo_id: $('#apo_id').val() },
          success: function(response,status,xhr) {
            if (response) {
              var optionsHtml='';
              for (var entry in response)
              {
                if(response.hasOwnProperty(entry))
                {
                  if(response[entry].indexOf('default')!=-1 || response[entry].indexOf('Assembly')!=-1)
                  {
                    optionsHtml+='<option selected="selected" value="'+entry+'">'+response[entry]+'</option>';
                  }
                  else
                  {
                    optionsHtml+='<option value="'+entry+'">'+response[entry]+'</option>';
                  }
                }
              }
              $('#rights').html(optionsHtml);
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

      $('#editing_dialog').dialog({
        autoOpen: false,
        buttons: { "Ok": function() { $(this).dialog("close"); } },
        modal: true,
        height: 260,
        title: 'Error',
        resizable: false
      });

      $('#invalid_dialog').dialog({
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
          },
          "Cancel": function() { $(this).dialog("close"); }
        },
        modal: true,
        height: 200,
        title: 'Confirm',
        resizable: false
      });

      $('#progress_dialog').dialog({
        autoOpen: false,
        height: 140,
        title: 'Progress',
        resizable: false
      });
      $('#progress').progressbar();
      $('#id_list').tabby();

      return(this);
    },

    initialize: function() {
      this.initializeContext().initializeDialogs().
        initializeGrid().initializeToolbar().initializeCallbacks();
    }
  };
  return($t);
}();

$(document).ready(function() {
  gridContext.initialize();
  $('#properties input,#properties select').change();
});

import pathTo from './pathTo'

export function gridContext() {
  const view_path = '/view'

  var statusFormatter = function(val, opts, rowObj) {
    if (val in $t.statusIcons) {
      var result = '<span class="' + $t.statusIcons[val] + '" title="' +
        (rowObj.error||val)+'" aria-hidden="true"></span>';
      if (rowObj.druid) {
        var href = view_path + "/druid:" + rowObj.druid;
        return '<a href="'+href+'" target="_blank">'+result+'</a>';
      }
      return(result)
    } else {
      return ' ';
    }
  };

  // Validates free-text tags fields and sets the .invalid class on elements
  // that aren't well formed tags
  let freeTagValidator = function(sender) {
    let value = sender.value.trim().split(/\s*:\s*/)
    sender.value = value.join(' : ')
    let invalid = (value.length == 1 && value[0] != '') ||
      (value.length > 1 && value.includes(''))
    sender.classList.toggle('invalid', invalid)
  }

  var $t = {
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
        this.resizeIdList();
      }
    },

    resizeIdList: function() {
      const boxHeight = Math.max($('#gbox_data .ui-jqgrid-bdiv').height(), 150)
      $('#id_list').animate({
        'top': $('#gbox_data .ui-jqgrid-hdiv').position().top + 3,
        'left': 3,
        'width': $('#gbox_data .ui-jqgrid-bdiv').width() - 4,
        'height' : $('#gbox_data .ui-jqgrid-hdiv').height() + boxHeight - 4
      }, 0);
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
        queued:  'registration-status icon-forward',
        pending: 'registration-status icon-refresh',
        success: 'registration-status icon-ok-sign',
        error:   'registration-status icon-exclamation-sign',
        abort: 'registration-status icon-remove-sign'
      };
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
          {label:'Barcode',name:'barcode_id',index:'barcode_id',width:150,editable:true},
          {label:'Catkey',name:'metadata_id',index:'metadata_id',width:150,editable:true,formatter:metadataIdFormatter},
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

      const template = document.getElementById('table-header')
      const clone = template.content.cloneNode(true)
      document.getElementById("t_data").appendChild(clone)

      $('#properties').show().insertBefore($('#dynamic .ui-userdata'))

      return(this);
    },

    initializeCallbacks: function() {
      document.querySelectorAll('input.free.tag-field').forEach(elem => {
        elem.addEventListener('blur', (event) => {
          freeTagValidator(event.target)
        })
      })

      return(this);
    },

    initializeDialogs: function() {
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

      return(this);
    },

    // Prevent the tab key from moving to the next input when pasting into the
    // "Text" section of the registration.
    allowTabsInTextarea: function() {
      document.getElementById('id_list').addEventListener('keydown', function(e) {
        if (e.key == 'Tab') {
          e.preventDefault();
          const start = this.selectionStart;
          const end = this.selectionEnd;

          // set textarea value to: text before caret + tab + text after caret
          this.value = `${this.value.substring(0, start)}\t${this.value.substring(end)}`

          // put caret at right position again
          this.selectionStart = this.selectionEnd = start + 1
        }
      })

      return(this);
    },
    initialize: function() {
      this.initializeContext().initializeDialogs().allowTabsInTextarea().
        initializeGrid().initializeCallbacks();
      $('#properties input,#properties select').change();
    }
  };
  return($t);
}

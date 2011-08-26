function DorRegistration() {
  var $t = {
    projectName: '',
    apoId: null,
    workflowId: null,
    mdFormId: null,
    metadataSource: null,
    tagList: "",
    registrationQueue: [],
    maxConcurrentRequests: 5,
    
    getTrackingSheet : function() {
      var project = $t.projectName;
      var druids = $('#data').getCol('druid');
      var sequence = 1;
      var query = $.param({ druid : druids, name : project, sequence : sequence });
      var url = pathTo("/registration/tracksheet?"+query);
      document.location.href = url;
    },
        
    register : function(rowid, progressFunction) {
      var apo = $t.apoId;
      var sourcePrefix = $t.metadataSource;
      progressFunction = progressFunction || function() {}

      if ($.isEmptyObject(apo) || $.isEmptyObject(sourcePrefix)) {
        $('#specify').dialog('open');
        return(false);
      }

      // Grab list of tags from textarea, split, and reject blanks
      var tags = $.grep($t.tagList.split('\n'), function(tag) { return tag.trim() == '' ? false : true })
      var project = $t.projectName;
      if (project) {
        tags.unshift('Project : '+project);
      }
      if ($t.mdFormId) {
        tags.unshift('MDForm : '+$t.mdFormId);
      }

      var data = $('#data').jqGrid('getRowData',rowid)
      data.id = rowid

      var params = { 
        'object_type' : 'item',
        'admin_policy' : apo,
        'workflow_id' : $t.workflowId,
        'seed_datastream' : ['descMetadata'],
        'label' : data.label || ':auto',
        'tag' : tags 
      }

      if (data.source_id) {
        params['source_id'] = data.source_id;
      }

      if (sourcePrefix != 'label') {
        params['other_id'] = sourcePrefix + ':' + data.metadata_id;
      }

      if (data.druid) {
        params['pid'] = 'druid:' + data.druid;
      } else if (sourcePrefix == 'mdtoolkit') {
        params['pid'] = "druid:" + data.metadata_id;
        if (!data.source_id) {
          params['source_id'] = params['pid']
        }
      }

      $t.setStatus(data, 'queued');
      $.ajax({
        type: 'POST',
        url: pathTo('/dor/objects'),
        data: context.params,
        success: function(response,status,xhr) { 
          if (response) {
            context.data.druid = response['pid'].split(':')[1];
            context.data.label = response['label'];
            context.progressFunction(xhr);
          }
        },
        error: function(xhr,status,errorThrown) {
          if (xhr.status < 500) {
            context.data.error = xhr.responseText;
          } else {
            context.data.error = xhr.statusText;
          }
          context.progressFunction(xhr);
        },
        complete: function(xhr,status) {
          $t.setStatus(context.data, status);
          $t.submitNext();
        },
        ajaxQ: 'register',
        realDataType: 'json'
      });
    },
    
    setStatus : function(data, status) {
      data.status = status;
      $('#data').jqGrid('setRowData', data.id, data);
    },

    registerAll : function() {
      var apo = $t.apoId;
      var sourcePrefix = $t.metadataSource;

      if ($.isEmptyObject(apo) || $.isEmptyObject(sourcePrefix)) {
        $('#specify').dialog('open');
        return(false);
      }

      var ids = $('#data').jqGrid('getDataIDs');
      var progressStep = 100 / $('#data').jqGrid('getDataIDs').length;
      var currentStep = 0;
      $('#progress').progressbar('option','value',currentStep);
      $('#progress_dialog').dialog('option','title','Registering '+ids.length+' items')
      $('#progress_dialog').dialog('open');
      for (var i = 0; i < ids.length; i++) {
        var rowid = ids[i];
        $t.register(rowid, function(xhr) {
          currentStep += progressStep;
          $('#progress').progressbar('option','value',currentStep);
          if (currentStep >= 99.999) { $('#progress_dialog').dialog('close'); }
        });
      }
      for (var i = 1; i <= $t.maxConcurrentRequests; i++) {
        $t.submitNext();
      }
    }
  };
  
  $.ajaxQ('register', { maxRequests: 10 });
  
  return($t);
}

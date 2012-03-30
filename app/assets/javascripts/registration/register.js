$.ajaxQ('register', { maxRequests: 10 });

function DorRegistration(initOpts) {
  var $t = {
    projectName: '',
    apoId: null,
    workflowId: null,
    mdFormId: null,
    metadataSource: null,
    tagList: "",
    registrationQueue: [],
    maxConcurrentRequests: 5,
    
    getTrackingSheet : function(druids) {
      var project = $t.projectName;
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
        $t.displayRequirements();
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

      var data = $t.getData(rowid);
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
      }

      var ajaxParams = {
        type: 'POST',
        url: pathTo('/dor/objects'),
        data: params,
        dequeued: function(xhr) {
          $t.setStatus(data, 'pending')
        },
        ajaxQ: 'register',
        dataType: 'json'
      }
      $t.setStatus(data, 'queued');
      var xhr = $.ajax(ajaxParams);
      xhr.success(function(response,status,xhr) { 
        if (response) {
          data.druid = response['pid'].split(':')[1];
          data.label = response['label'];
          progressFunction(xhr);
        }
      });
      xhr.error(function(xhr,status,errorThrown) {
        if (xhr.status < 500) {
          data.error = xhr.responseText;
        } else {
          data.error = xhr.statusText;
        }
        progressFunction(xhr);
      });
      xhr.complete(function(xhr,status) {
          $t.setStatus(data, status);
      });
    },

    registerAll : function() {
      var apo = $t.apoId;
      var sourcePrefix = $t.metadataSource;

      if ($.isEmptyObject(apo) || $.isEmptyObject(sourcePrefix)) {
        $t.displayRequirements();
        return(false);
      }

      var ids = $t.getDataIds();
      $t.progress(true);
      for (var i = 0; i < ids.length; i++) {
        var rowid = ids[i];
        $t.register(rowid, function(xhr) {
          $t.progress();
        });
      }
    }
  };
  
  $.extend($t, initOpts);

  return($t);
}

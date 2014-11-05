$.ajaxQ('register', { maxRequests: 10 });

function DorRegistration(initOpts) {
  var $t = {
    defaultValues: {
      objectType: 'item',
      projectName: '',
      apoId: 'druid:hv992ry2431',
      workflowId: null,
      mdFormId: null,
      metadataSource: 'none',
      tagList: "",
      collection: 'None'
    },

    registrationQueue: [],
    maxConcurrentRequests: 5,

    setDefault : function(param) {
      if (param == null) {
        for (param in $t.defaultValues) { $t.setDefault(param) }
      } else {
        $t[param] = $t.defaultValues[param]
      }
    },

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

      // Grab list of tags from textarea, split, and reject blanks
      var tags = $.grep($t.tagList.split('\n'), function(tag) { return tag.trim() == '' ? false : true })
      var project = $t.projectName;
      if ($t.mdFormId) {
        tags.unshift('MDForm : '+$t.mdFormId);
      }

      var data = $t.getData(rowid);
      data.id = rowid

      var params = {
        'object_type' : $t.objectType,
        'admin_policy' : apo,
        'workflow_id' : $('#workflow_id').val(),
        'seed_datastream' : ($t.metadataSource == 'none' || $t.metadataSource == 'label' ) ? null : ['descMetadata'],
        'metadata_source' : ($t.metadataSource != 'label') ? null : $t.metadataSource,
        'label' : data.label || ':auto',
        'tag' : tags,
        'rights' : $('#rights').val(),
        'collection' : collection.value
      }

      if (data.source_id) {
        params['source_id'] = data.source_id;
      }

      if (sourcePrefix != 'none') {
        params['other_id'] = sourcePrefix + ':' + data.metadata_id;
      }

      if (data.druid) {
        params['pid'] = 'druid:' + data.druid;
      } else if (sourcePrefix == 'mdtoolkit') {
        params['pid'] = "druid:" + data.metadata_id;
      }

      for (x in params) { if (params[x] == null) { delete params[x] } }

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

    validate : function() {
      var apo = $t.apoId;
      var sourcePrefix = $t.metadataSource;
      switch($t.objectType) {
        case 'item':
          if ($.isEmptyObject(apo) || $.isEmptyObject(sourcePrefix)) {
            $t.displayRequirements('Please specify both an Admin Policy and a Metadata Source before continuing.');
            return(false);
          }
          break;
        case 'collection':
        case 'set':
          if ($.isEmptyObject(apo)) {
            $t.displayRequirements('Please specify an Admin Policy before continuing.');
            return(false);
          }
          return(false);
          break;
      }
      //if the metadata source is auto, figure out whether it should be label, symphony or mdtoolkit based on what is in the mdsource field
      if (sourcePrefix != 'none') {
        var mdIds = $('#data').jqGrid('getCol','metadata_id')
        if(mdIds[0].trim().length==0)
        {
            //no md source, set to label
            $t.metadataSource = 'label';
        }
        else
        {
            var intRegex = /^\d+$/;
            //if it is an integer, it is a catkey or barcode
            if(intRegex.test(mdIds[0].trim()))
            {
                $t.metadataSource = 'symphony';
            }
            else
            {
                $t.metadataSource = 'mdtoolkit';
            }
        }
        //check for mixed md sources, that isnt allowed
        for(mdId in mdIds)
        {
            var trimmed=mdIds[mdId].trim();
            var intRegex = /^\d+$/;
            //if it is an integer, it is a catkey or barcode
            if(intRegex.test(trimmed) &&  $t.metadataSource != 'symphony')
            {
                $t.displayRequirements('You have mixed metadata sources, the first item indicates '+$t.metadataSource+' but "'+trimmed+'" implies symphony.');
                return false;
            }
            if(trimmed == '' && $t.metadataSource != 'label')
            {
                $t.displayRequirements('You have mixed metadata sources, the first item indicates '+$t.metadataSource+' but "'+trimmed+'" implies label.');
                return false;
            }
            if(trimmed.indexOf('druid')>0 && $t.metadataSource != 'mdtoolkit')
            {
                $t.displayRequirements('You have mixed metadata sources, the first item indicates '+$t.metadataSource+' but "'+trimmed+'" implies mdtoolkit.');
                return false;
            }
        }
        sourcePrefix = $t.metadataSource;
        if (sourcePrefix != 'label'){
          if ($.grep(mdIds,function(id,index) { return id.trim() == '' }).length > 0) {
            $t.displayRequirements('Metadata source was detected as"' + sourcePrefix + '", which requires metadata IDs for all items.');
            return(false);
          }
        }
      }

      //check for missing source ids
      var source_ids = $('#data').jqGrid('getCol','source_id')
      if ($.grep(source_ids,function(id,index) { return id.trim() == '' }).length > 0) {
        $t.displayRequirements('Source ids must be set for all items.');
        return(false);
      }
      //check for missing labels if not using a metadata source
      if(sourcePrefix == 'none' || sourcePrefix== 'label')
      {
        var source_ids = $('#data').jqGrid('getCol','label')
        if ($.grep(source_ids,function(id,index) { return id.trim() == '' }).length > 0) {
          $t.displayRequirements('Labels must be set for all items.');
          return(false);
        }
      }

      return(true)
    },

    registerAll : function() {
      var apo = $t.apoId;
      var sourcePrefix = $t.metadataSource;
      if (this.validate()) {
        var ids = $t.getDataIds();
        $t.progress(true);
        for (var i = 0; i < ids.length; i++) {
          var rowid = ids[i];
          $t.register(rowid, function(xhr) {
            $t.progress();
          });
        }
      }
    }
  };

  $.extend($t, initOpts);
  return($t);
}

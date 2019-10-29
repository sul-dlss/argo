
import pathTo from './pathTo'

export default function DorRegistration(initOpts) {
  var $t = {
    defaultValues: {
      objectType: 'item',
      projectName: '',
      apoId: 'druid:hv992ry2431',   // TODO: uber APO druid must be pulled from config, not hardcoded
      workflowId: null,
      mdFormId: null,
      metadataSource: 'Auto',
      tagList: "",
      collection: 'None'
    },

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
        'seed_datastream' : ($t.metadataSource === 'label' ) ? null : ['descMetadata'],
        'metadata_source' : ($t.metadataSource !== 'label') ? null : $t.metadataSource,
        'label' : data.label || ':auto',
        'tag' : tags,
        'rights' : $('#rights').val(),
        'collection' : collection.value
      }

      if (data.source_id) {
        params.source_id = data.source_id;
      }

      params.other_id = sourcePrefix + ':' + data.metadata_id;

      if (data.druid) {
        params.pid = 'druid:' + data.druid;
      }

      for (let x in params) { if (params[x] == null) { delete params[x] } }

      var ajaxParams = {
        type: 'POST',
        url: pathTo('/dor/objects'),
        data: params,
        beforeSend: function(xhr) {
          $t.setStatus(data, 'pending')
        },
        dataType: 'json',
        success: function(response,status,xhr) {
          if (response) {
            data.druid = response['pid'].split(':')[1];
            data.label = response['label'];
            progressFunction(xhr);
          }
        },
        error: function(xhr,status,errorThrown) {
          if (xhr.status < 500) {
            data.error = xhr.responseText;
          } else {
            data.error = xhr.statusText;
          }
          progressFunction(xhr);
        },
        complete: function(xhr,status) {
            $t.setStatus(data, status);
        },
      }
      $t.setStatus(data, 'queued');
      var xhr = $.ajax(ajaxParams);
    },

    validate : function() {
      if ($.isEmptyObject($t.apoId)) {
        $t.displayRequirements('Please specify an Admin Policy before continuing.');
        return false
      }

      const intRegex = /^\d+$/;

      // Figure out whether metadataSource should be label or symphony based on what is in the catkey field
      var mdIds = $('#data').jqGrid('getCol','metadata_id')
      if(mdIds[0].trim().length === 0) {
          // no md source, set to label
          $t.metadataSource = 'label';
      } else if(intRegex.test(mdIds[0].trim())) {
          // if it is an integer, it is a catkey or barcode
          $t.metadataSource = 'symphony';
      }
      //check for mixed md sources, that isnt allowed
      for(var mdId in mdIds) {
          var trimmed=mdIds[mdId].trim();
          // if it is an integer, it is a catkey or barcode
          if ($t.metadataSource === 'label') {
            if(intRegex.test(trimmed)) {
                $t.displayRequirements('You have mixed metadata sources, the first item indicates label but "'+trimmed+'" implies symphony.');
                return false;
            }
          } else if(trimmed === '') {
              $t.displayRequirements('You have mixed metadata sources, the first item indicates symphony but "" implies label.');
              return false;
          }
      }
      var sourcePrefix = $t.metadataSource;
      if (sourcePrefix === 'symphony') {
        if ($.grep(mdIds,function(id) { return id.trim() === '' }).length > 0) {
          $t.displayRequirements('Metadata source was detected as "symphony", which requires metadata IDs for all items.');
          return false
        }
      } else {
        //check for missing labels if not using a catkey
        const labels = $('#data').jqGrid('getCol','label')
        if ($.grep(labels, function(label) { return label.trim() === '' }).length > 0) {
          $t.displayRequirements('Labels must be set for all items.');
          return false
        }
      }

      //check for missing source ids
      var source_ids = $('#data').jqGrid('getCol','source_id')
      if ($.grep(source_ids,function(id) { return id.trim() === '' }).length > 0) {
        $t.displayRequirements('Source ids must be set for all items.');
        return false
      }

      return true
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

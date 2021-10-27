import pathTo from './pathTo'

export default function DorRegistration(initOpts) {
  var $t = {
    getTrackingSheet : function(druids) {
      var project = $t.projectName();
      var sequence = 1;
      var query = $.param({ druid : druids, name : project, sequence : sequence });
      var url = pathTo("/registration/tracksheet?"+query);
      document.location.href = url;
    },

    apoId : function() { 
      return document.querySelector('[data-rcparam="apoId"]').value
    },

    projectName : function() {
      // algolia autocomplete duplicates the field, so we need to check the name rather than
      // the data-rcparam attribute.
      return document.querySelector('[name="project"]').value
    },

    collection : function() { 
      return document.querySelector('[data-rcparam="collection"]').value
    },

    workflowId : function() { 
      return document.querySelector('[data-rcparam="workflowId"]').value
    },

    rights: function() {
      return document.getElementById('rights').value
    },

    register : function(rowid, progressFunction) {
      progressFunction = progressFunction || function() {}

      // Grab list of tags from the form and rejects blanks
      var tags = Array.from(document.querySelectorAll('#properties .tag-field')).map((elem) => {
        var value = elem.value
        if (elem.disabled || value == null || value.trim() == '')
          return null

        const prefix = elem.dataset.tagname
        return prefix ? `${prefix} : ${value}` : value
      }).filter(n => n)

      var data = $t.getData(rowid);
      data.id = rowid

      var params = {
        'admin_policy' : this.apoId(),
        'project' : this.projectName(),
        'workflow_id' : this.workflowId(),
        'label' : data.label || ':auto',
        'tag' : tags,
        'rights' : this.rights(),
        'collection' : this.collection()
      }

      if (data.source_id) {
        params.source_id = data.source_id;
      }

      if (data.barcode_id) {
        params.barcode_id = data.barcode_id
      }
      params.other_id = $t.metadataSource + ':' + data.metadata_id;

      if (data.druid) {
        params.pid = 'druid:' + data.druid;
      }

      for (let x in params) { if (params[x] == null) { delete params[x] } }

      $t.setStatus(data, 'queued');

      // Grab the CSRF token from the meta tag (null-coalescing operator for the test environment)
      const csrfToken = document.querySelector("[name='csrf-token']")?.content
      fetch(pathTo('/dor/objects'), {
        method: 'POST',
        headers: {
          "X-CSRF-Token": csrfToken,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(params),
      })
      .then(response => {
        if (!response.ok) {
          data.error = response.statusText
          console.error(response)
          $t.setStatus(data, 'error');
        } else {
          response.json().then(json => {
            console.log(json)
            data.druid = json['pid'].split(':')[1];
            data.label = json['label'];
            $t.setStatus(data, 'success');
          })
        }
        progressFunction()
      })
      .catch(error => {
        console.error(error)
      })
    },

    validate : function() {
      if (!$t.apoId()) {
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
      if ($t.metadataSource === 'symphony') {
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
      if (this.validate()) {
        var ids = $t.getDataIds();
        $t.progress(true);
        for (var i = 0; i < ids.length; i++) {
          var rowid = ids[i];
          $t.register(rowid, function() {
            $t.progress();
          });
        }
      }
    }
  };

  $.extend($t, initOpts);
  return($t);
}

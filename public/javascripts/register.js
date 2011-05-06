function DorRegistration() {
  this.getTrackingSheet = function() {
    var project = $('#project').val();
    var druids = $('#data').getCol('druid');
    var sequence = 1;
    var query = $.param({ druid : druids, name : project, sequence : sequence });
    var url = "tracksheet?"+query;
    document.location.href = url;
  },
  
  this.register = function(rowid, progressFunction) {
    var apo = $('#apo_id').val();
    var sourcePrefix = $('#id_source').val();
    progressFunction = progressFunction || function() {}
    
    if (apo == '' || sourcePrefix == '') {
      $('#specify').dialog('open');
      return(false);
    }
    
    // Grab list of tags from textarea, split, and reject blanks
    var tags = $.grep($('#tag_list').val().split('\n'), function(tag) { return tag.trim() == '' ? false : true })
    var project = $('#project').val();
    if (project) {
      tags.unshift('Project : '+project);
    }
    
    var data = $('#data').jqGrid('getRowData',rowid)
    data.id = rowid
    
    var params = { 
      'object_type' : 'item',
      'admin_policy' : apo,
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

    data.status = 'pending';
    $('#data').jqGrid('setRowData', data.id, data);
    
    var xhr = $.ajax({
      type: 'POST',
      url: '../dor/objects',
      data: params,
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
        data.status = status;
        $('#data').jqGrid('setRowData', data.id, data);
      },
      dataType: 'json'
    });
    return(xhr);
  }

  this.registerAll = function() {
    var apo = $('#apo_id').val();
    var sourcePrefix = $('#id_source').val();
    
    if (apo == '' || sourcePrefix == '') {
      $('#specify').dialog('open');
      return(false);
    }
    
    var register = this.register;
    var ids = $('#data').jqGrid('getDataIDs');
    var progressStep = 100 / $('#data').jqGrid('getDataIDs').length;
    var currentStep = 0;
    $('#progress').progressbar('option','value',currentStep);
    $('#progress_dialog').dialog('option','title','Registering '+ids.length+' items')
    $('#progress_dialog').dialog('open');
    for (var i = 0; i < ids.length; i++) {
      var rowid = ids[i];
      register(rowid, function(xhr) {
        currentStep += progressStep;
        $('#progress').progressbar('option','value',currentStep);
        if (currentStep >= 99.999) { $('#progress_dialog').dialog('close'); }
      });
    }
  }
  
}

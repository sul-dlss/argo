function DorRegistration() {

  this.register = function(rowid) {
    var apo = $('#apo_id').val();
    var sourcePrefix = $('#id_source').val();
    
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
      'label' : data.label || ':auto',
      'tags' : tags 
    }

    if (sourcePrefix != 'label') {
      params['source_id'] = sourcePrefix + ':' + data.identifier;
    }
    
    if (data.druid) {
      params['pid'] = 'druid:' + data.druid;
    } else if (sourcePrefix == 'mdtoolkit') {
      params['pid'] = "druid:" + data.identifier;
    }

    data.status = 'pending';
    $('#data').jqGrid('setRowData', data.id, data);
    
    $.ajax({
      type: 'POST',
      url: '/dor/objects',
      data: params,
      success: function(response,status,xhr) { 
        data.druid = response['pid'].split(':')[1];
        data.status = 'complete';
        data.label = response['label'];
        $('#data').jqGrid('setRowData', data.id, data);
      },
      error: function(xhr,status,errorThrown) {
        data.status = 'error';
        if (xhr.status < 500) {
          data.label = xhr.responseText;
        } else {
          data.label = xhr.statusText;
        }
        $('#data').jqGrid('setRowData', data.id, data);
      },
      dataType: 'json'
    });
  }

  this.registerAll = function() {
    var apo = $('#apo_id').val();
    var sourcePrefix = $('#id_source').val();
    
    if (apo == '' || sourcePrefix == '') {
      $('#specify').dialog('open');
      return(false);
    }
    
    var register = this.register;
    $('#data').jqGrid('getDataIDs').map(function(rowid) {
      register(rowid);
    });
  }

}

function DorRegistration(apo, sourcePrefix, tags, identifiers, statusImages) {
  this.apo = apo;
  this.sourcePrefix = sourcePrefix;
  this.tags = tags;
  this.identifiers = identifiers;
  this.statusImages = statusImages;
  
  $([this.statusImages.pending, this.statusImages.complete, this.statusImages.error]).preload();
  
  this.register = function(index) {
    var statusImages = this.statusImages;
    var table = $('#results').dataTable();
    var row = $("#dor_"+index.toString())[0];
    table.fnUpdate('<img src="'+statusImages['pending']+'">', row, 0);
    
    var params = { 
      'object_type' : 'item',
      'admin_policy' : this.apo, 
      'label' : ':auto',
      'source_id' : this.sourcePrefix + ':' + this.identifiers[index], 
      'tags' : this.tags 
    }
    if (this.sourcePrefix == 'mdtoolkit') {
      params['pid'] = "druid:" + this.identifiers[index];
    }
    
    $.ajax({
      type: 'POST',
      url: 'objects',
      data: params,
      success: function(data,status,xhr) { 
        var pid = data['pid'].split(':')[1];
        table.fnUpdate('<img src="'+statusImages['complete']+'">', row, 0);
        table.fnUpdate('<a href="' + data['location'] + '">' + pid + '</a>', row, 3);
        table.fnUpdate(data['label'], row, 4);
      },
      error: function(xhr,status,errorThrown) {
        console.dir(xhr);
        var row = $("#dor_"+index.toString())[0];
        var table = $('#results').dataTable();
        table.fnUpdate('<img src="'+statusImages['error']+'" title="'+xhr.status+" "+xhr.statusText+'">', row, 0);
        table.fnUpdate(status, row, 3);
        if (xhr.status < 500) {
          table.fnUpdate(xhr.responseText, row, 4);
        } else {
          table.fnUpdate(xhr.statusText, row, 4);
        }
      },
      dataType: 'json'
    });
  }

  this.registerAll = function() {
    for (var i = 0; i < this.identifiers.length; i++) {
      this.register(i);
    }
  }
  
}

$(document).ready(function() {
  $("a.dialogLink").each(function() {
    var dialog_box = "empty";
    var link = $(this);
    $(this).click( function() {     
      //lazy create of dialog
      if ( dialog_box == "empty") {
        dialog_box = $('<div class="dialog_box"/>').dialog({ autoOpen: false });  
      }
      $.get(this.href).complete(function(xhr) {
        dialog_box.dialog('option','title',link.text());
        dialog_box.dialog('option','position',['100px','100px']).dialog('option','width',$(window).width()-200).dialog('option','height',$(window).height()-200);
        $(dialog_box).html(xhr.responseText)
        $("body").css("cursor", "auto");
        dialog_box.dialog('open');
      });
      $("body").css("cursor", "progress");
      return false; // do not execute default href visit
    });

  });
})

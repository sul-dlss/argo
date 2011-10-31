$(document).ready(function() {
  $("a.xmlLink").each(function() {
    var dialog_box = "empty";
    var link = $(this);
    $(this).click( function() {     
      //lazy create of dialog
      if ( dialog_box == "empty") {
        dialog_box = $('<div class="dialog_box"><pre class="prettyprint lang-xml"/></div>').dialog({ autoOpen: false });  
      }
      // Load the original URL on the link into the dialog associated
      // with it. Rails app will give us an appropriate partial.
      // pull dialog title out of first heading in contents. 
      $("body").css("cursor", "progress");
      $.get(this.href).complete(function(xhr) {
        var xml = xhr.responseText.replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;');
        dialog_box.dialog('option','title',link.text());
        dialog_box.dialog('option','position',['100px','100px']).dialog('option','width',$(window).width()-200).dialog('option','height',$(window).height()-200);
        $('pre',dialog_box).html(xml)
        prettyPrint();
        $("body").css("cursor", "auto");
        dialog_box.dialog('open');
      });

      return false; // do not execute default href visit
    });

  });
})

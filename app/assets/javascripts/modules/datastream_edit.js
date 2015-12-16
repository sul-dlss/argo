/*global Blacklight */
'use strict';

(function($) {
  /*
    jQuery plugin that validates datastream xml editor
  */

  $.fn.datastreamEdit = function() {
    return this.each(function() {
      $.validator.addMethod('xmlWellFormedness', function (value) {
        try {
          return $.parseXML(value) != null;
        } catch(err) { 
          return false; 
        }
      }, 'XML must be well-formed.');
      $('#xmlEditForm').validate({
        debug: true,
        rules: {
          content: {
            required: true,
            xmlWellFormedness: true
          }
        }
      });
    });
  };
})(jQuery);

Blacklight.onLoad(function() {
  $('#xmlEditForm').datastreamEdit();
});

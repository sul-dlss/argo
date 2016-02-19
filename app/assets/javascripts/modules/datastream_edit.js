/*global Blacklight */
'use strict';

(function($) {
  /*
    jQuery plugin that validates datastream XML editor to ensure the XML
    is parseable before the user submits the datastream update.
  */
  $.fn.datastreamXmlEdit = function() {
    return this.each(function() {
      $.validator.addMethod('xmlWellFormedness', function (value) {
        try {
          return $.parseXML(value) != null;
        } catch(err) { 
          return false; 
        }
      }, 'XML must be well-formed.');
      $('#xmlEditForm').validate({
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

/*
   Because we are in a modal dialog we need to use the 'loaded' event
   to trigger the form validation setup.
 */
Blacklight.onLoad(function() {
  $('body').on('loaded.persistent-modal', function() {
    $('#xmlEditForm').datastreamXmlEdit();
  });
});
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

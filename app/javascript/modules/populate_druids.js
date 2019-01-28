/*global Blacklight */
'use strict';

(function($) {
  /*
    jQuery plugin that requests and displays druids from a catalog search
  */

  $.fn.populateDruids = function() {
    function getAndUpdatePids(url, target) {
      $.getJSON(url)
      .done(function(data) {
        var docs = '';
        $.each(data.response.docs, function(i, value) {
          docs += value.id + '\n';
        });

        $(target).val(docs);
      });
    }

    return this.each(function() {
      var $el = $(this);
      var url = $el.data('populateDruids');
      var target = $el.data('target');
      $el.on('click', function() {
        getAndUpdatePids(url, target);
      });
    });
  };

})(jQuery);

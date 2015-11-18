/*global Blacklight */
'use strict';

(function($) {
  /*
    jQuery plugin that enables buttons by checking their url
  */

  $.fn.buttonChecker = function() {
    return this.each(function() {
      var $el = $(this);
      var url = $el.data('check-url');
      $.getJSON(url)
        .done(function(data) {
          if (data) {
            $el.removeClass('disabled');
          }
        });
    });
  };

})(jQuery);

Blacklight.onLoad(function() {
  $('a.disabled[data-check-url]').buttonChecker();
});

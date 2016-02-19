/*global Blacklight */
'use strict';

(function($) {
  /*
    jQuery plugin that requests and displays Index Queue Depth
  */

  $.fn.indexQueueDepth = function() {
    return this.each(function() {
      var $el = $(this);
      var url = $el.data('index-queue-depth-url');
      $.getJSON(url)
      .done(function(data) {
        if (data > 1000) {
          $el.parent().addClass('text-warning');
        }
        switch(data) {
          case null:
            $el.text('-');
            break;
          default:
            $el.text(data);
        }
      });
    });
  };
  

})(jQuery);

Blacklight.onLoad(function() {
  $('[data-index-queue-depth-url]').indexQueueDepth();
});

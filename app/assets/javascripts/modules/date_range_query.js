/*global Blacklight */
'use strict';

(function($) {
  /*
    jQuery plugin that enables date range selections. Updates hidden query field
    for the form.
  */

  $.fn.dateRangeQuery = function() {

    function craftQuery($beforeDate, $afterDate) {
      var afterDate = $afterDate.val();
      var beforeDate = $beforeDate.val();
      var query = '[';
      if (afterDate.length > 0) {
        query += new Date(Date.parse(afterDate)).toISOString() + ' TO ';
      } else {
        query += '* TO ';
      }
      if (beforeDate.length > 0) {
        // Add the selected date + 23 hours, 59 minutes, 59 seconds
        query += new Date(Date.parse(beforeDate) + 86399000)
          .toISOString() + ']';
      } else {
        query += '*]';
      }
      return query;
    }

    return this.each(function() {
      var $el = $(this);
      var $beforeDate = $el.find('[data-range-before]');
      var $afterDate = $el.find('[data-range-after]');
      var $queryField = $el.find('[data-range-value]');
      
      $beforeDate.on('change', function() {
        $queryField.val(craftQuery($beforeDate, $afterDate));
      });
      
      $afterDate.on('change', function() {
        $queryField.val(craftQuery($beforeDate, $afterDate));
      });
    });

  };

})(jQuery);

Blacklight.onLoad(function() {
  $('[data-range-query]').dateRangeQuery();
  $('[data-datepicker]').datepicker();
});

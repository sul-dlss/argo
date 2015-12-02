/*global Blacklight */
'use strict';

(function($) {
  /*
    jQuery plugin that enables date range selections. Ported from legacy Argo 
    code in app/assets/javascript/argo.js
  */

  $.fn.dateRangeQuery = function() {

    function assembleQuery($el, facet) {
    	var beforeDate = $el.find('[data-range-before]')
        .datepicker({ dateFormat: 'yyyy-mm-dd' }).val();
      var afterDate = $el.find('[data-range-after]')
        .datepicker({ dateFormat: 'dd-mm-yy' }).val();
      var qf='f[' + facet + '][]=';

      if (afterDate !== '') {
        afterDate = new Date(Date.parse(afterDate));
        qf += '[' + afterDate.toISOString() + ' TO';
      } else {
        qf += '[* TO';
    	}
      
    	if (beforeDate !== '') {
        beforeDate = new Date(Date.parse(beforeDate));
        qf += ' ' + beforeDate.toISOString() + ']';
      } else {
        qf += ' *]';
    	}
    	return qf;
    }


    return this.each(function() {
      var $el = $(this);
      var $button = $el.find('button');
      var facet = $button.data().facetQuery;
      var path = $el.data().rangePath;
      
      $button.on('click', function(e) {
        e.preventDefault();
        var query = assembleQuery($el, facet);
        document.location = path + '?' + query;
      });
    });

  };

})(jQuery);

Blacklight.onLoad(function() {
  $('[data-range-query]').dateRangeQuery();
  $('[data-datepicker]').datepicker();
});

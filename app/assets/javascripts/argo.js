// Put your application scripts here

$.fn.preload = function() {
    this.each(function(){
        $('<img/>')[0].src = this;
    });
}

function pathTo(path) {
  var root = $('body').attr('data-application-root') || '';
  return(root + path);
}

$(document).ready(function() {
  $('#page').wrapInner('<div id="argonauta"/>');
  $('#logo h1').remove();
  $('.start-open').addClass('twiddle-open');
  $('.start-open').next('ul').show();
  $('.collapsible-section').click(function() { $(this).next('div').slideToggle(); $(this).toggleClass('collapsed') })
});

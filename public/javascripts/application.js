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
  $('#doc4').wrapInner('<div id="argonauta"/>');
  $('#hd div div.first').remove();
  $('#hd div div.user_util_links').removeClass('yui-u');
  $('.start-open').addClass('twiddle-open');
  $('.start-open').next('ul').show();
});

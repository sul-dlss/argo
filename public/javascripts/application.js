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
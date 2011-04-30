// Put your application scripts here

$.fn.preload = function() {
    this.each(function(){
        $('<img/>')[0].src = this;
    });
}
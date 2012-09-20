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
  $('#facets a.remove').map(function() { $(this).html('') })
});
function assembleQuery(caller)
{
	var field_name=caller.id;
	var before_date=$('#'+field_name+'_before_datepicker').datepicker({ dateFormat: 'yyyy-mm-dd' }).val();
	if(before_date!='')
		before_date=new Date(Date.parse(before_date));
	var after_date=$('#'+field_name+'_after_datepicker').datepicker({ dateFormat: 'dd-mm-yy' }).val();
	if(after_date!='')
		after_date=new Date(Date.parse(after_date));
	var qf="f["+field_name.replace('_date','_dt')+"][]=";
	if(after_date!='')
	{
		qf+="["+getXMLSchemaDateTime(after_date)+' TO';
	}
	else
	{
		qf+="[* TO";
	}
	if(before_date!='')
	{
		qf+=" "+getXMLSchemaDateTime(before_date)+"]";
	}
	else
	{
		qf+=" *]";
	}
	document.location='view?'+qf;
}
function getXMLSchemaDateTime(d){
    // padding function
    var s = function(a,b){
    a=a+'';
    while(a.length<b)
    {a='0'+a;}
    return a;
    };

    // default date parameter
    

    // return ISO datetime
    return d.getFullYear() + '-' +
        s(d.getMonth()+1,2) + '-' +
        s(d.getDate(),2) + 'T' +
        s(d.getHours(),2) + ':' +
        s(d.getMinutes(),2) + ':' +
        s(d.getSeconds(),2) + 'Z';
}

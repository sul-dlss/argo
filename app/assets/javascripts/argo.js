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
    $('#logo h1').remove();
    $('.start-open').addClass('twiddle-open');
    $('.start-open').next('ul').show();
    $('.collapsible-section').click(function(e) {
        // Do not want a click on the "MODS bulk loads" button to cause collapse
        if(!(e.target.id === 'bulk-button')) {
            $(this).next('div').slideToggle();
            $(this).toggleClass('collapsed'); 
        }
    });
    
    $('#facets a.remove').map(function() { $(this).html('') })
});


Blacklight.onLoad(function(){
    // For lightboxes, set the title to be the value of the data-ajax-modal-title attribute on the link if
    // present. Otherwise just use the link text as the title.
    $(Blacklight.ajaxModal.triggerLinkSelector).click(function(){
        if($(this).attr('data-ajax-modal-title'))
            $('.modal-title').text($(this).attr('data-ajax-modal-title'));
        else 
            $('.modal-title').text($(this).text());
    });

    // make the default modal resizable and draggable.  resize from top and side borders (things got
    // wonky with corner and bottom resizing, in what little testing i did).
    $(".modal-dialog").resizable({handles: "n, e, w"});
    $(".modal-dialog").draggable({});

    // when the modal is closed, reset its size and position.
    $(".modal-dialog .close").on("click", function() {
        // draggable and resizable do their respective things via a local style attr, so just clear that.
        $(".modal-dialog").attr("style", "");
    });
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


// When a user selects a spreadsheet file for uploading via the bulk metadata upload function,
// this function is called to verify the filename extension.
function validate_spreadsheet_filetype()
{
    var filename = $('#spreadsheet_file').val().toLowerCase();
    $('span#bulk-spreadsheet-warning').text("");
    
    // Use lastIndexOf() since endsWith() is part of the latest ECMAScript 6 standard and not implemented
    // in Poltergeist/PhantomJS yet.
    if((filename.lastIndexOf(".xlsx") == -1) && (filename.lastIndexOf(".xls") == -1) &&  (filename.lastIndexOf(".xml") == -1) && (filename.lastIndexOf(".csv") == -1))
        $('span#bulk-spreadsheet-warning').text("Note: Only spreadsheets or XML files are allowed. Please check your selected file.");
}

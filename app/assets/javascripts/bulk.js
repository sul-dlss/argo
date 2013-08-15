
function open_version(druids){
	cons=[];
	var params={
		'severity': $('#severity').val(),
		'description': $('#description').val(),
	}
	$.each(druids, function(i,element){
		var element_url=catalog_url(element);
		url=open_version_url.replace('xxxxxxxxx',element);
		var xhr=$.ajax({url: url, type: 'POST', data: params});
		cons.push(xhr);
		xhr.success(function(response,status,xhr) { 
			success_handler(element_url, 'Prepared', show_buttons);
		})
		xhr.error(function(xhr,status,err){error_handler(xhr,status,err,element_url,job_count.pop(),show_buttons)})
	})
}
function close_version(druids){
	var params={
		'severity': $('#severity').val(),
		'description': $('#description').val(),
	}
	cons=[];
	$.each(druids, function(i,element){
		var element_url=catalog_url(element);
		url=close_version_url.replace('xxxxxxxxx',element);
		var xhr=$.ajax({url: url, type: 'POST', data: params});
		cons.push(xhr);
		xhr.success(function(response,status,xhr) { 
			success_handler(element_url, 'Closed');
		})
		xhr.error(function(xhr,status,err){error_handler(xhr,status,err,element_url,job_count.pop())})
	})
}
function set_content_type(druids){
	var params={
		'new_content_type': $('#new_content_type').val(),
		'new_resource_type': $('#new_resource_type').val(),
		'old_content_type': $('#old_content_type').val(),
		'old_resource_type': $('#old_resource_type').val()
	}
	cons=[];
	$.each(druids, function(i,element){
     	var	element_url=catalog_url(element);
		url=set_content_type_url.replace('xxxxxxxxx',element);
		var xhr=$.ajax({url: url, type: 'POST', data: params});
		cons.push(xhr);
		xhr.success(function(response,status,xhr) { 
			success_handler(element_url, 'Updated');
		})
		xhr.error(function(xhr,status,err){error_handler(xhr,status,err,element,job_count.pop())})
	})
}


function fix_provenance(druids){
	cons=[];
	$.each(druids, function(i,element){
		var element_url=catalog_url(element);
		url=fix_provenance_url.replace('xxxxxxxxx',element);
		var xhr=$.ajax({url: url, type: 'GET'});
		cons.push(xhr);
		xhr.success(function(response,status,xhr) { 
			success_handler(element_url, 'Provenance added.');
		})
		xhr.error(function(xhr,status,err){error_handler(xhr,status,err,element_url,job_count.pop())})
	})
}
function purge(druids){
	cons=[];
	$.each(druids, function(i,element){
		var element_url=catalog_url(element);
		url=purge_url.replace('xxxxxxxxx',element);
		var xhr=$.ajax({url: url, type: 'GET'});
		cons.push(xhr);
		xhr.success(function(response,status,xhr) { 
			success_handler(element_url, 'Purged');
		})
		xhr.error(function(xhr,status,err){error_handler(xhr,status,err,element_url,job_count.pop())})
	})
}

function fetch_druids(fun)
{
	$(".stop_button").show();
	log=document.getElementById('log');
	log.style.display="block";
	if(document.getElementById('pids').value.length>5)
	{
		txt=document.getElementById('pids').value
		txt=txt.replace(/druid:/g,'');
		druids=txt.split("\n");
		last=druids.pop();
		if(last != ''){druids.push(last);}
		log.innerHTML="Using "+ druids.length +" user supplied druids.\n<br>"
		job_count=[]
		for(i=druids.length;i>0;i--)
		{
			job_count.push(i);
		}
		fun(druids);
	}
	else{
		log.innerHTML="Fetching all "+report_model['total_rows']+" druids.<br>\n"
		$.getJSON(report_model['data_url'], function(data){
			report_model['druids']=[]
			$.each(data.druids, function(i,s){
				report_model['druids'].push(s);
			});
			log.innerHTML=log.innerHTML+"Received "+report_model['druids'].length+" pids, starting work<br>\n"
			fun(report_model['druids']);
		}).error(function(jqXhr, textStatus, error) {
			alert("ERROR: " + textStatus + ", " + error);
		});
	}
}
function reindex(druids){
	cons=[]
	$.each(druids, function(i,element){
		var element_url=catalog_url(element);
		url=reindex_url.replace('xxxxxxxxx',element);
		var xhr=$.ajax({url: url, type: 'GET'});
		cons.push(xhr);
		xhr.success(function(response,status,xhr) { 
			success_handler(element_url, 'Reindexed.');
			
		})
		xhr.error(function(xhr,status,err){error_handler(xhr,status,err,element_url,job_count.pop())})
	})
}
function republish(druids){
	cons=[]
	$.each(druids, function(i,element){
		var element_url=catalog_url(element);
		url=republish_url.replace('xxxxxxxxx',element);
		var xhr=$.ajax({url: url, type: 'GET'});
		cons.push(xhr);
		xhr.success(function(response,status,xhr) { 
			success_handler(element_url, 'Republished.');
			
		})
		xhr.error(function(xhr,status,err){error_handler(xhr,status,err,element_url,job_count.pop())})
	})
}
function release_hold(druids){
	cons=[]
	$.each(druids, function(i,element){
		var element_url=catalog_url(element);
		url=release_hold_url.replace('xxxxxxxxx',element);
		var xhr=$.ajax({url: url, type: 'POST'});
		cons.push(xhr);
		xhr.success(function(response,status,xhr) { 
			success_handler(element_url, 'Hold released.');
			
		})
		xhr.error(function(xhr,status,err){error_handler(xhr,status,err,element_url,job_count.pop())})
	})
}
function set_rights(druids){
	cons=[];
	var params={
		'rights': $('#rights_select').val(),
	}
	$.each(druids, function(i,element){
		var element_url=catalog_url(element);
		url=set_rights_url.replace('xxxxxxxxx',element);
		var xhr=$.ajax({url: url, type: 'POST', data: params});
		cons.push(xhr);
		xhr.success(function(response,status,xhr) { 
			success_handler(element_url,'Updated');
		})
		xhr.error(function(xhr,status,err){error_handler(xhr,status,err,element_url,job_count.pop())})
	})
}

function create_desc_md(druids){
	cons=[];
	$.each(druids, function(i,element){
		var element_url=catalog_url(element);
		url=create_desc_md_url.replace('xxxxxxxxx',element);
		var xhr=$.ajax({url: url, type: 'GET'});
		cons.push(xhr);
		xhr.success(function(response,status,xhr) { 
			success_handler(element_url,'Updated');
		})
		xhr.error(function(xhr,status,err){error_handler(xhr,status,err,element_url,job_count.pop())})
	})
}
function add_collection(druids){
	cons=[];
	var params={
		'collection': $('#collection_select').val(),
	}
	$.each(druids, function(i,element){
		var element_url=catalog_url(element);
		url=add_collection_url.replace('xxxxxxxxx',element);
		var xhr=$.ajax({url: url, type: 'POST', data: params});
		cons.push(xhr);
		xhr.success(function(response,status,xhr) { 
			success_handler(element_url,'Updated');
		})
		xhr.error(function(xhr,status,err){error_handler(xhr,status,err,element_url,job_count.pop())})
	})
}
function detect_duplicate_encoding(druids){
	cons=[];
	$.each(druids, function(i,element){
		var element_url=catalog_url(element);
		url=url.replace('xxxxxxxxx',element);
		var xhr=$.ajax({url: url, type: 'GET'});
		cons.push(xhr);
		xhr.success(function(response,status,xhr) { 
			success_handler(element_url,'No duplicates');
		})
		xhr.error(function(xhr,status,err){error_handler(xhr,status,err,element_url,job_count.pop())})
	})
}
function remove_duplicate_encoding(druids){
	cons=[];
	$.each(druids, function(i,element){
		var element_url=catalog_url(element);
		url=remove_duplicate_encoding_url.replace('xxxxxxxxx',element);
		var xhr=$.ajax({url: url, type: 'GET'});
		cons.push(xhr);
		xhr.success(function(response,status,xhr) { 
			success_handler(element_url,'Fixed');
		})
		xhr.error(function(xhr,status,err){error_handler(xhr,status,err,element_url,job_count.pop())})
	})
}
function schema_validate(druids){
	cons=[];
	$.each(druids, function(i,element){
		var element_url=catalog_url(element);
		url=schema_validate_url.replace('xxxxxxxxx',element);
		var xhr=$.ajax({url: url, type: 'GET'});
		cons.push(xhr);
		xhr.success(function(response,status,xhr) { 
			success_handler(element_url,'Valid');
		})
		xhr.error(function(xhr,status,err){error_handler(xhr,status,err,element_url,job_count.pop())})
	})
}
function discoverable(druids){
	cons=[];
	$.each(druids, function(i,element){
		var element_url=catalog_url(element);
		url=discoverable_url.replace('xxxxxxxxx',element);
		var xhr=$.ajax({url: url, type: 'GET'});
		cons.push(xhr);
		xhr.success(function(response,status,xhr) { 
			success_handler(element_url,'Discovable.');
		})
		xhr.error(function(xhr,status,err){error_handler(xhr,status,err,element_url,job_count.pop())})
	})
}
function remediate_mods(druids){
	cons=[];
	$.each(druids, function(i,element){
		var element_url=catalog_url(element);
		url=remediate_mods_url.replace('xxxxxxxxx',element);
		var xhr=$.ajax({url: url, type: 'GET'});
		cons.push(xhr);
		xhr.success(function(response,status,xhr) { 
			success_handler(element_url,'Fixed');
		})
		xhr.error(function(xhr,status,err){error_handler(xhr,status,err,element_url,job_count.pop())})
	})
}
function expedite(druids){
	cons=[];
	$.each(druids, function(i,element){
		var element_url=catalog_url(element);
		url=expedite_url.replace('xxxxxxxxx',element);
		var xhr=$.ajax({url: url, type: 'GET'});
		cons.push(xhr);
		xhr.success(function(response,status,xhr) { 
			success_handler(element_url,'Expedited');
		})
		xhr.error(function(xhr,status,err){error_handler(xhr,status,err,element_url,job_count.pop())})
	})
}

function apply_apo_defaults(druids){
	cons=[];
	$.each(druids, function(i,element){
		var element_url=catalog_url(element);
		url=apo_apply_defaults_url.replace('xxxxxxxxx',element);
		var xhr=$.ajax({url: url, type: 'GET'});
		cons.push(xhr);
		xhr.success(function(response,status,xhr) { 
			success_handler(element_url,'Defaults applied.');
		})
		xhr.error(function(xhr,status,err){error_handler(xhr,status,err,element_url,job_count.pop())})
	})
}
function add_workflow(druids){
	cons=[];
	var params={
		'wf': $('#wf').val(),
	}
	$.each(druids, function(i,element){
		var element_url=catalog_url(element);
		url=add_workflow_url.replace('xxxxxxxxx',element);
		var xhr=$.ajax({url: url, type: 'POST', data: params});
		cons.push(xhr);
		xhr.success(function(response,status,xhr) { 
			success_handler(element_url,'Workflow Added');
		})
		xhr.error(function(xhr,status,err){error_handler(xhr,status,err,element_url,job_count.pop())})
	})
}

function refresh_metadata(druids){
	cons=[];
	$.each(druids, function(i,element){
		var element_url=catalog_url(element);
		url=refresh_metadata_url.replace('xxxxxxxxx',element);
		var xhr=$.ajax({url: url, type: 'GET'});
		cons.push(xhr);
		xhr.success(function(response,status,xhr) { 
			success_handler(element_url,'Updated');
		})
		xhr.error(function(xhr,status,err){error_handler(xhr,status,err,element_url,job_count.pop())})
	})
}
function get_druids()
{
	log=document.getElementById('pids');
	$('#pid_list').show(400);
	log.innerHTML=log.innerHTML+'Fetching druids...'+"\n"
	$.getJSON(report_model['data_url'], function(data){
		report_model['druids']=[];
		log.innerHTML='';
		$.each(data.druids, function(i,s){
			report_model['druids'].push(s);
			log.innerHTML=log.innerHTML+'druid:'+s+"\n"
		});
	}).error(function(jqXhr, textStatus, error) {
		alert("ERROR: " + textStatus + ", " + error);
	});
}
function get_source_ids()
{
	log=document.getElementById('source_ids');
	$.getJSON(report_model['data_url']+'&source_id=true', function(data){
		report_model['druids']=[]
		$.each(data.druids, function(i,s){
			report_model['druids'].push(s);
			log.innerHTML=log.innerHTML+'druid:'+s+"\n"
		});
	}).error(function(jqXhr, textStatus, error) {
		alert("ERROR: " + textStatus + ", " + error);
	});
}
function show_buttons()
{
	$('#updates').show(400);
	$('.update_buttons').removeAttr("disabled");
}
function stop_all()
{
	log=document.getElementById('log');
	
	while(cons.length>0)
	{
		con=cons.pop();
		con.abort();
	}
}
//print a success message with whatever description fits the action being performed.
function success_handler(element_url,desc,after)
{
	if (job_count.length == 1 && after != null)
	{
		after();
	}
	log=document.getElementById('log');
	log.innerHTML = job_count.pop()+" "+element_url+' '+desc+"<br>\n"+log.innerHTML;
	if (job_count.length == 0)
	{
		log.innerHTML = "Done!\n<br>"+log.innerHTML
    	$(".stop_button").hide();
	}
}
function error_handler(xhr,status,err,element,index, after){
	if (job_count.length == 1 && after != null)
	{
		after();
	}
	msg='';
	if( xhr.responseText && xhr.responseText.length<500)
	{
		msg=xhr.responseText;
	}
	else
	{
		msg=err;
	}
		log.innerHTML = "<span class=\"error\"> "+index+" "+element+" : "+msg+"</span><br>\n"+log.innerHTML;	
		if (job_count.length == 0)
		{
			log.innerHTML = "Done!<br>\n"+log.innerHTML
			$(".stop_button").hide();
		}
	
}

function source_id(){
	cons=[];
	log=document.getElementById('log');
	log.style.display="block";
	txt=document.getElementById('source_ids').value
	txt=txt.replace(/druid:/g,'');
	druids=txt.split("\n")
	last=druids.pop();
	if(last != ''){druids.push(last);}
	d=[]
	for(i=druids.length;i>0;i--)
	{
		job_count.push(i);
	}
	for(i=0;i< druids.length; i++)
	{
		dr=druids[i];
		dr=dr.replace(/ : /g,':');
		parts=dr.split("\t",2);
		d.push({'druid': parts[0], 'source': parts[1]});
	}
	log.innerHTML="Using "+ druids.length +" user supplied druids and source ids.<br>\n"
	log=document.getElementById('log');
	$.each(d, function(i,element){
		//get rid of blank lines
		if(element['druid'] == null || element['druid'].length < 2)
		{
			return;
		}
		var element_url=catalog_url(element['druid']);
		//skip bad source ids
		if(element['source']==null || element['source'].length<=1 || element['source'].indexOf(':')<1)
		{
			err_log=document.getElementById('log');

			err_log.innerHTML = "<span class=\"error\"> "+job_count.pop()+" "+element_url+" : invalid source id '"+element['source']+"'</span><br>\n"+log.innerHTML;
			return;
		}
		params={
			'new_id': element['source']
		}
		url=source_id_url.replace('xxxxxxxxx',element['druid']);
		var xhr=$.ajax({url: url, type: 'POST', data: params});
		cons.push(xhr);
		xhr.success(function(response,status,xhr) { 
			success_handler(element_url, 'Updated	');
		})
		xhr.error(function(xhr,status,err){error_handler(xhr,status,err,element_url,job_count.pop())})
})
}
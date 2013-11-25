
function process_get(druids, action_url, success_string){
	cons=[];
	$.each(druids, function(i,element){
		var element_url=catalog_url(element);
		url=action_url.replace('xxxxxxxxx',element);
		var xhr=$.ajax({url: url, type: 'GET'});
		cons.push(xhr);
		xhr.success(function(response,status,xhr) { 
			success_handler(element_url, success_string);
		})
		xhr.error(function(xhr,status,err){error_handler(xhr,status,err,element_url,job_count.pop())})
	})
}

function process_post(druids, action_url, params, success_string){
	cons=[];
	$.each(druids, function(i,element){
		var element_url=catalog_url(element);
		url=action_url.replace('xxxxxxxxx',element);
		var xhr=$.ajax({url: url, type: 'POST', data: params});
		cons.push(xhr);
		xhr.success(function(response,status,xhr) { 
			success_handler(element_url, success_string, show_buttons);
		})
		xhr.error(function(xhr,status,err){error_handler(xhr,status,err,element_url,job_count.pop(),show_buttons)})
	})
	
}
function open_version(druids){
	var params={
		'severity': $('#severity').val(),
		'description': $('#description').val(),
	}
	process_post(druids, open_version_url, params, "Prepared");
}
function close_version(druids){
	var params={
		'severity': $('#severity').val(),
		'description': $('#description').val(),
	}
	process_post(druids, close_version_url, params, "Closed");
}
function set_content_type(druids){
	var params={
		'new_content_type': $('#new_content_type').val(),
		'new_resource_type': $('#new_resource_type').val(),
		'old_content_type': $('#old_content_type').val(),
		'old_resource_type': $('#old_resource_type').val()
	}
	process_post(druids,set_content_type_url, params, "Updated");
}


function fix_provenance(druids){
	process_get(druids, provenance_url, "Provenance added.");
}
function purge(druids){
	process_get(druids, purge_url, "Purged");
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
	process_get(druids, reindex_url, 'Reindexed.');
}
function republish(druids){
	process_get(druids, republish_url, "Republished.");
}
function release_hold(druids){
	process_post(druids,'',release_hold_url, "Hold released.")
}
function set_rights(druids){
	var params={
		'rights': $('#rights_select').val(),
	}
	process_post(druids, params, rights_url, "Updated");
}
function create_desc_md(druids){
	process_get(druids, create_desc_md_url ,"Updated");
}
function add_collection(druids){
	process_post(druid, params, add_collection_url, "Updated");
}
function detect_duplicate_encoding(druids){
	process_get(druids, detect_duplicate_encoding_url, 'No Duplicates.');
}
function remove_duplicate_encoding(druids){
	process_get(druids, remove_duplicate_encoding_url, "fixed");
}
function schema_validate(druids){
	process_get(druids, schema_valudate_url, "Valid");
}
function discoverable(druids){
	process_get(druids, discoverable_url, "Dicoverable");
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
	process_get(druids, apo_apply_defaults_url, 'Defaults_applied.')
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
	process_get(druids, refresh_metadata_url, "Updated.");
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
function get_tags()
{
	log=document.getElementById('tags');
	$.getJSON(report_model['data_url']+'&tags=true', function(data){
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
function set_tags(){
	cons=[];
	job_count = [];
	log=document.getElementById('log');
	log.style.display="block";
	txt=document.getElementById('tags').value
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
		parts=dr.split("\t");
		druid=parts.shift();
		tags=parts.join("\t");
		d.push({'druid': druid, 'tags': tags});
	}
	log.innerHTML="Using "+ druids.length +" user supplied druids and tags.<br>\n"
	log=document.getElementById('log');
	$.each(d, function(i,element){
		//get rid of blank lines
		if(element['druid'] == null || element['druid'].length < 2)
		{
			return;
		}
		var element_url=catalog_url(element['druid']);
		//skip bad source ids
		if(element['tags']==null || element['tags'].length<=1 || element['tags'].indexOf(':')<1)
		{
			err_log=document.getElementById('log');

			err_log.innerHTML = "<span class=\"error\"> "+job_count.pop()+" "+element_url+" : invalid tags '"+element['source']+"'</span><br>\n"+log.innerHTML;
			return;
		}
		params={
			'tags': element['tags']
		}
		url=tags_url.replace('xxxxxxxxx',element['druid']);
		var xhr=$.ajax({url: url, type: 'POST', data: params});
		cons.push(xhr);
		xhr.success(function(response,status,xhr) { 
			success_handler(element_url, 'Updated	');
		})
		xhr.error(function(xhr,status,err){error_handler(xhr,status,err,element_url,job_count.pop())})
})
}
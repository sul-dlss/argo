function process_request(druids, action_url, req_type, req_params, success_string, success_handler_callback, error_handler_callback) {
	cons = [];
	$.each(druids, function(i, element) {
		var element_url = catalog_url(element);
		var url = action_url.replace('xxxxxxxxx', element);
		var req_obj = {url: url, type: req_type};
		if(req_params != null) req_obj['data'] = req_params;
		var xhr = $.ajax(req_obj);
		cons.push(xhr);
		xhr.success(function(response, status, xhr) { 
			success_handler(element_url, success_string, success_handler_callback);
		});
		xhr.error(function(xhr, status, err) {
			error_handler(xhr, status, err, element_url, job_count.pop(), error_handler_callback);
		});
	})
}

function process_get(druids, action_url, success_string) {
	process_request(druids, action_url, 'GET', null, success_string);
}

function process_post(druids, action_url, req_params, success_string) {
	process_request(druids, action_url, 'POST', req_params, success_string, show_buttons, show_buttons);
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
	process_get(druids, fix_provenance_url, "Provenance added.");
}
function purge(druids){
	process_get(druids, purge_url, "Purged");
}

function fetch_pids_txt() {
	return document.getElementById('pids').value.trim();
}

function extract_pids_list(pids_txt) {
	//get rid of the 'druid:' prefixes, declare helper funcs, split the text on line breaks, trim each line, discard empties
	pids_txt = pids_txt.replace(/druid:/g, '');
	var str_trim_fn = function(str) {return str.trim();};
	var str_is_not_empty_fn = function(str) {return str != null && str.length > 0;};
	return pids_txt.split("\n").map(str_trim_fn).filter(str_is_not_empty_fn);
}

function get_druids_req(log, wait_msg, druid_each_callback, preprocessing_callback, postprocessing_callback, req_url) {
	log.innerHTML = wait_msg;
	if (req_url == null) req_url = report_model['data_url'];
	$.getJSON(req_url, function(data) {
		report_model['druids'] = [];
		if (preprocessing_callback != null) { preprocessing_callback(); }
		$.each(data.druids, druid_each_callback);
		if (postprocessing_callback != null) { postprocessing_callback(); }
	}).error(function(jqXhr, textStatus, error) {
		alert("ERROR: " + textStatus + ", " + error);
	});
}

function fetch_druids(fun) {
	$(".stop_button").show();
	log = document.getElementById('log');
	log.style.display = "block";
	var pids_txt = fetch_pids_txt();
	if(pids_txt.length > 5) {
		druids = extract_pids_list(pids_txt);

		log.innerHTML = "Using " + druids.length + " user supplied druids.\n<br>";
		job_count = [];
		for(i=druids.length; i>0; i--) {
			job_count.push(i);
		}
		fun(druids);
	} else {
		job_count = [];
		total_rows = report_model['total_rows'];
		var wait_msg = "Fetching all " + total_rows + " druids.<br>\n";
		var druid_each_callback = function(i, s) { report_model['druids'].push(s); job_count.push(total_rows-i); };
		var postprocessing_callback = function() {
			log.innerHTML = log.innerHTML + "Received " + report_model['druids'].length + " pids, starting work<br>\n";
			fun(report_model['druids']);
		};
		get_druids_req(log, wait_msg, druid_each_callback, null, postprocessing_callback);
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
	var params = {rights: $('#rights_select').val()}
	process_post(druids, set_rights_url, params, "Updated");
}
function create_desc_md(druids){
	process_get(druids, create_desc_md_url ,"Updated");
}
function set_collection(druids){
	var collection_id = document.getElementById('set_collection_select').value;
	process_post(druids, set_collection_url, {collection: collection_id}, "Collection added");
}
function add_collection(druids){
	var collection_id = document.getElementById('add_collection_select').value;
	process_post(druids, add_collection_url, {collection: collection_id}, "Collection added");
}
function detect_duplicate_encoding(druids){
	process_get(druids, detect_duplicate_encoding_url, 'No Duplicates.');
}
function remove_duplicate_encoding(druids){
	process_get(druids, remove_duplicate_encoding_url, "fixed");
}
function schema_validate(druids){
	process_get(druids, schema_validate_url, "Valid");
}
function discoverable(druids){
	process_get(druids, discoverable_url, "Dicoverable");
}
function remediate_mods(druids){
	return; //disabled for now
	process_get(druids, remediate_mods_url, 'Fixed');
}

function apply_apo_defaults(druids){
	process_get(druids, apo_apply_defaults_url, 'Defaults_applied.')
}

function add_workflow(druids){
	var params={ 'wf': $('#wf').val() }
	process_post(druids, add_workflow_url, params, 'Workflow Added');
}


function refresh_metadata(druids){
	process_get(druids, refresh_metadata_url, "Updated.");
}

function get_druids() {
	var log = document.getElementById('pids');
	$('#pid_list').show(400);

	var wait_msg = log.innerHTML+"Fetching druids...\n";
	var druid_each_callback = function(i, s) { report_model['druids'].push(s); log.innerHTML = log.innerHTML+"druid:"+s+"\n"; };
	var preprocessing_callback = function() {log.innerHTML='';};
	get_druids_req(log, wait_msg, druid_each_callback, preprocessing_callback);
}

// create a callback function that will request a list of druids based on the current search, but which
// will also filter the list of druids on the list the user entered in the pids list text area, so that 
// unwanted druids can get filtered out of search results.  useful for, e.g., get_source_ids and get_tags.
function get_filtered_druid_each_callback(log) {
	var pids_txt = fetch_pids_txt();
	var selected_druids = (pids_txt.length > 5) ? extract_pids_list(pids_txt) : null; //in case the user entered druids on which to filter
	var druid_each_callback = function(i, s) {
		var cur_druid_only = s.trim().replace(/\s.*/g, ''); //trim and get just pre-whitespace chars for comparison to user entered druids
		if (selected_druids == null || $.inArray(cur_druid_only, selected_druids) >= 0) {
			report_model['druids'].push(s);
			log.innerHTML = log.innerHTML + 'druid:' + s + "\n";
		}
	};

	return druid_each_callback;
}

function get_source_ids() {
	var log = document.getElementById('source_ids');
	var druid_each_callback = get_filtered_druid_each_callback(log);
	var req_url = report_model['data_url']+'&source_id=true';
	get_druids_req(log, null, druid_each_callback, null, null, req_url);
}

function get_tags() {
	var log = document.getElementById('tags');
	var druid_each_callback = get_filtered_druid_each_callback(log);
	var req_url = report_model['data_url']+'&tags=true';
	get_druids_req(log, null, druid_each_callback, null, null, req_url);
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

function source_id() {
	cons = [];
	log = document.getElementById('log');
	log.style.display = "block";
	txt = document.getElementById('source_ids').value;
	txt = txt.replace(/druid:/g, '');
	druids = txt.split("\n")
	last = druids.pop();
	if (last != '') {druids.push(last);}
	d = [];
	job_count = [];
	for (i=druids.length; i>0; i--) {
		job_count.push(i);
	}
	for (i=0; i<druids.length; i++) {
		dr = druids[i];
		dr = dr.replace(/ : /g,':');
		parts = dr.split("\t", 2);
		d.push({'druid': parts[0], 'source': parts[1]});
	}
	log.innerHTML = "Using " + druids.length + " user supplied druids and source ids.<br>\n";
	log = document.getElementById('log');
	$.each(d, function(i, element) {
		//get rid of blank lines
		if(element['druid'] == null || element['druid'].length < 2) {
			return;
		}
		var element_url = catalog_url(element['druid']);
		//skip bad source ids
		if(element['source']==null || element['source'].length<=1 || element['source'].indexOf(':')<1) {
			err_log = document.getElementById('log');
			err_log.innerHTML = "<span class=\"error\"> "+job_count.pop()+" "+element_url+" : invalid source id '"+element['source']+"'</span><br>\n"+log.innerHTML;
			return;
		}
		params = { 'new_id': element['source'] };
		url = source_id_url.replace('xxxxxxxxx',element['druid']);
		var xhr = $.ajax({url: url, type: 'POST', data: params});
		cons.push(xhr);
		xhr.success(function(response,status,xhr) { 
			success_handler(element_url, 'Updated	');
		});
		xhr.error(function(xhr,status,err){error_handler(xhr,status,err,element_url,job_count.pop())});
	})
}

function set_tags() {
	cons = [];
	log = document.getElementById('log');
	log.style.display = "block";
	txt = document.getElementById('tags').value;
	txt = txt.replace(/druid:/g,'');
	druids = txt.split("\n");
	last = druids.pop();
	if (last != '') {druids.push(last);}
	d = [];
	job_count = [];
	for (i=druids.length; i>0; i--) {
		job_count.push(i);
	}
	for(i=0; i<druids.length; i++) {
		dr = druids[i];
		dr = dr.replace(/ : /g,':');
		parts = dr.split("\t");
		druid = parts.shift();
		tags = parts.join("\t");
		d.push({'druid': druid, 'tags': tags});
	}
	log.innerHTML = "Using " + druids.length +" user supplied druids and tags.<br>\n";
	log = document.getElementById('log');
	$.each(d, function(i, element) {
		//get rid of blank lines
		if(element['druid'] == null || element['druid'].length < 2) {
			return;
		}
		var element_url=catalog_url(element['druid']);
		//skip bad source ids
		if(element['tags']==null || element['tags'].length<=1 || element['tags'].indexOf(':')<1) {
			err_log = document.getElementById('log');
			err_log.innerHTML = "<span class=\"error\"> "+job_count.pop()+" "+element_url+" : invalid tags '"+element['source']+"'</span><br>\n"+log.innerHTML;
			return;
		}
		params = { 'tags': element['tags'] };
		url = tags_url.replace('xxxxxxxxx',element['druid']);
		var xhr=$.ajax({url: url, type: 'POST', data: params});
		cons.push(xhr);
		xhr.success(function(response,status,xhr) { 
			success_handler(element_url, 'Updated	');
		})
		xhr.error(function(xhr,status,err){error_handler(xhr,status,err,element_url,job_count.pop())})
	})
}
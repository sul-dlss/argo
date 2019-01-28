function process_request(druids, action_url, req_type, req_params, success_string, success_handler_callback, error_handler_callback) {
	cons = [];
	$.each(druids, function(i, druid) {
		var object_link = catalog_url(druid);
		var url = action_url.replace('xxxxxxxxx', druid);
		var req_obj = {url: url, type: req_type};
		if(req_params != null) req_obj['data'] = req_params;
		var xhr = $.ajax(req_obj);
		cons.push(xhr);
		xhr.success(function(response, status, xhr) {
			success_handler(object_link, success_string, success_handler_callback);
		});
		xhr.error(function(xhr, status, err) {
			error_handler(xhr, status, err, object_link, job_count.pop(), error_handler_callback);
		});
	})
}

function process_get(druids, action_url, success_string) {
	process_request(druids, action_url, 'GET', null, success_string);
}

function process_post(druids, action_url, req_params, success_string) {
	process_request(druids, action_url, 'POST', req_params, success_string, show_buttons, show_buttons);
}

function process_patch(druids, action_url, req_params, success_string) {
	process_request(druids, action_url, 'PATCH', req_params, success_string, show_buttons, show_buttons);
}

function open_version(druids){
	var params={
		'severity': $('#severity').val(),
		'description': $('#description').val(),
	}
	process_post(druids, open_version_url, params, "Prepared");
}
function close_version(druids){
	process_post(druids, close_version_url, null, "Closed");
}
function set_content_type(druids){
	var params={
		'new_content_type': $('#new_content_type').val(),
		'new_resource_type': $('#new_resource_type').val(),
		'old_content_type': $('#old_content_type').val(),
		'old_resource_type': $('#old_resource_type').val()
	}
	process_patch(druids, set_content_type_url, params, "Updated");
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
	}).fail(function(jqXhr, textStatus, error) {
		alert("ERROR: " + textStatus + ", " + error);
	});
}

function fetch_druids(fun) {
	$(".stop_button").show();
	log = document.getElementById('log');
	log.style.display = "block";
	var pids_txt = fetch_pids_txt();
	if(pids_txt.length > 5) {
		var druids = extract_pids_list(pids_txt);

		log.innerHTML = "Using " + druids.length + " user supplied druids.\n<br/>";
		job_count = [];
		for(i=druids.length; i>0; i--) {
			job_count.push(i);
		}
		fun(druids);
	} else {
		job_count = [];
		total_rows = report_model['total_rows'];
		var wait_msg = "Fetching all " + total_rows + " druids.<br/>\n";
		var druid_each_callback = function(i, s) { report_model['druids'].push(s); job_count.push(total_rows-i); };
		var postprocessing_callback = function() {
			log.innerHTML = log.innerHTML + "Received " + report_model['druids'].length + " pids, starting work<br/>\n";
			fun(report_model['druids']);
		};
		get_druids_req(log, wait_msg, druid_each_callback, null, postprocessing_callback);
	}
}

function republish(druids){
	process_get(druids, republish_url, "Republished.");
}

function set_rights(druids){
	var params = {rights: $('#rights_select').val()}
	process_post(druids, set_rights_url, params, "Updated");
}
function set_collection(druids){
	var collection_id = document.getElementById('set_collection_select').value;
	process_post(druids, set_collection_url, {collection: collection_id}, "Collection set");
}

function apply_apo_defaults(druids){
	process_get(druids, apo_apply_defaults_url, 'Defaults_applied.')
}

function add_workflow(druids){
	var params = { 'wf': $('#wf').val() }
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


function show_buttons() {
	$('#updates').show(400);
	$('.update_buttons').removeAttr("disabled");
}

function stop_all() {
	log = document.getElementById('log');

	while(cons.length > 0) {
		con = cons.pop();
		con.abort();
	}
}

//print a success message with whatever description fits the action being performed.
function success_handler(object_link, desc, after) {
	if (job_count.length == 1 && after != null) {
		after();
	}

	var log = document.getElementById('log');
	log.innerHTML = '&nbsp;' + job_count.pop() + ' ' + object_link + ' : <span class="text-success">' + desc + "</span><br/>\n" + log.innerHTML;
	if (job_count.length == 0) {
		log.innerHTML = "Done!\n<br/>"+log.innerHTML;
    $(".stop_button").hide();
	}
}

function error_handler(xhr, status, err, object_link, index, after) {
	if (job_count.length == 1 && after != null) {
		after();
	}
  err = (status + " : " + err).substr(0, 500); // include both status and error message returned from response; truncate message if too long
  err = jQuery('<div>' + err + '</div>').text(); // strip any HTML from error message, adding <div> ensures there's HTML
	var log = document.getElementById('log');
	log.innerHTML = '&nbsp;' + index + ' ' + object_link + ' : <span class="text-danger">' + err + "</span><br/>\n" + log.innerHTML;
	if (job_count.length == 0) {
		log.innerHTML = "Done!<br/>\n" + log.innerHTML;
		$(".stop_button").hide();
	}

}

function upd_values_for_druids(upd_req_url, upd_textarea_id, row_processing_fn, custom_wait_msg, is_invalid_row_fn, invalid_row_err_msg, get_upd_req_params_from_row_fn) {
	cons = [];
	var log = document.getElementById('log');
	log.style.display = "block";

	var druid_upd_txt = document.getElementById(upd_textarea_id).value;
	var druid_upd_lines = extract_pids_list(druid_upd_txt);
	job_count = [];
	for (i=druid_upd_lines.length; i>0; i--) {
		job_count.push(i);
	}

	var druid_upd_rows = [];
	for (i=0; i<druid_upd_lines.length; i++) {
		dr = druid_upd_lines[i];
		dr = dr.replace(/ : /g,':');
		row_result = row_processing_fn(dr);
		druid_upd_rows.push(row_result);
	}
	log.innerHTML = "Using " + druid_upd_lines.length + " " + custom_wait_msg + "<br/>\n";

	$.each(druid_upd_rows, function(i, upd_info) {
		//get rid of blank lines
		if(upd_info['druid'] == null || upd_info['druid'].length < 2) {
			return;
		}
		var object_link = catalog_url(upd_info['druid']);

		//skip bad rows
		if(is_invalid_row_fn(upd_info)) {
			log.innerHTML = "<span class=\"text-danger\"> "+job_count.pop()+" "+object_link+" : "+invalid_row_err_msg+" '"+upd_info['upd_data']+"'</span><br/>\n"+log.innerHTML;
			return;
		}
		var params = get_upd_req_params_from_row_fn(upd_info);
		var url = upd_req_url.replace('xxxxxxxxx', upd_info['druid']);
		var xhr = $.ajax({url: url, type: 'POST', data: params});
		cons.push(xhr);
		xhr.success(function(response, status, xhr) {
			success_handler(object_link, 'Updated	');
		});
		xhr.error(function(xhr, status, err) {
			error_handler(xhr, status, err, object_link, job_count.pop());
		});
	});
}

function source_id() {
	var row_processing_fn = function(row_str) {
		parts = row_str.split("\t", 2);
		row_result = {'druid': parts[0], 'upd_data': parts[1]};
		return row_result;
	};
	var is_invalid_row_fn = function(row_obj) { return (row_obj['upd_data']==null || row_obj['upd_data'].length<=1 || row_obj['upd_data'].indexOf(':')<1); };
	var get_upd_req_params_from_row_fn = function(row_obj) { return { 'new_id': row_obj['upd_data'] }; };
	upd_values_for_druids(source_id_url, 'source_ids', row_processing_fn, "user supplied druids and source ids.", is_invalid_row_fn, "invalid source id", get_upd_req_params_from_row_fn);
}

function set_tags() {
	var row_processing_fn = function(row_str) {
		parts = row_str.split("\t");
		druid = parts.shift();
		tags = parts.join("\t");
		row_result = {'druid': druid, 'upd_data': tags};
		return row_result;
	};
	var is_invalid_row_fn = function(row_obj) { return (row_obj['upd_data']==null || row_obj['upd_data'].length<=1 || row_obj['upd_data'].indexOf(':')<1); };
	var get_upd_req_params_from_row_fn = function(row_obj) { return { 'tags': row_obj['upd_data'] }; };
	upd_values_for_druids(tags_url, 'tags', row_processing_fn, "user supplied druids and tags.", is_invalid_row_fn, "invalid tags", get_upd_req_params_from_row_fn);
}

Blacklight.onLoad(()=>{
  $('#get_druids').on('click', get_druids)
	$('#paste-druids-button').on('click', () => $('#pid_list').show(400))
	$('#prepare').on('click', () => $('#open').show(400))
	$('#refresh-mods-button').on('click', () => $('#refresh_metadata').show(400))
	$('#show_source_id').on('click', () => {
		$('#source_id').show(400)
	  get_source_ids()
	})
	$('#set-object-rights-button').on('click', () => $('#rights').show(400))
	$('#set-content-type-button').on('click', () => $('#content_type').show(400))
	$('#set-collection-button').on('click', () => $('#set_collection').show(400))

	$('#apply-apo-defaults-button').on('click', () => $('#apply_apo_defaults').show(400))
	$('#add-workflow-button').on('click', () => $('#add_workflow').show(400))
	$('#close-versions-button').on('click', () => $('#close').show(400))
  $('#republish_show').on('click', () => $('#republish').show(400))
  $('#show_tags').on('click', () => {
		$('#tag').show(400)
		get_tags()
	})
  $('#purge-button').on('click', () => $('#purge').show(400))
	$('#prepare_button').on('click', () => {
		fetch_druids(open_version)
		$('#open').hide(400)
	})

	$('#close-objects-button').on('click', () => {
		fetch_druids(close_version)
		$('#close').hide(400)
	})

  $('#confirm-apo-defaults-button').on('click', () => {
		fetch_druids(apply_apo_defaults)
		$('#apply_apo_defaults').hide(400)
	})

	$('#confirm-set-collection-button').on('click', () => {
		fetch_druids(set_collection)
		$('#set_collection').hide(400)
	})

	$('#confirm-set-content-type-button').on('click', () => {
		fetch_druids(set_content_type)
		$('#content_type').hide(400)
	})

	$('#confirm-set-content-type-button').on('click', () => {
		fetch_druids(purge)
		$('#purge').hide(400)
	})

	$('#confirm-add-workflow-button').on('click', () => {
		fetch_druids(add_workflow)
		$('#add_workflow').hide(400)
	})

	$('#confirm-refresh-metadata-button').on('click', () => {
		fetch_druids(refresh_metadata)
		$('#refresh_metadata').hide(400)
	})

  $('#republish_button').on('click', () => {
		fetch_druids(republish)
		$('#republish').hide(400)
	})

	$('#set_tags').on('click', () => {
		set_tags()
		$('#tag').hide(400)
	})

	$('#set_source_id').on('click', () => {
		source_id()
		$('#source_id').hide(400)
	})

	$('#rights_button').on('click', () => {
			fetch_druids(set_rights)
			$('#rights').hide(400)
	})

	$('#stop').on('click', () => stop_all())
})

/**
 * These functions support "Bulk Update (synchronous)"
 */

function process_request(druids, action_url, req_type, req_params, success_string, success_handler_callback, error_handler_callback) {
	cons = [];
	$.each(druids, function(i, druid) {
		const object_link = catalog_url(druid);
		const url = action_url.replace('xxxxxxxxx', druid);
		if(!req_params) req_params = {}
		req_params.authenticity_token = Blacklight.csrfToken()
		const req_obj = { url: url, type: req_type, data: req_params }
		const xhr = $.ajax(req_obj);
		cons.push(xhr);
		xhr.done(function(response, status, xhr) {
			success_handler(object_link, success_string, success_handler_callback);
		});
		xhr.fail(function(xhr, status, err) {
			error_handler(xhr, status, err, object_link, job_count.pop(), error_handler_callback);
		});
	})
}

function process_post(druids, action_url, req_params, success_string) {
	process_request(druids, action_url, 'POST', req_params, success_string, show_buttons, show_buttons);
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

function set_rights(druids){
	var params = { 'dro_rights_form[rights]': document.getElementById('rights_select').value }
	process_post(druids, set_rights_url, params, "Updated");
}

function set_collection(druids){
	var collection_id = document.getElementById('set_collection_select').value;
	process_post(druids, set_collection_url, {collection: collection_id}, "Collection set");
}

function get_druids() {
	var log = document.getElementById('pids');
	$('#pid_list').show(400);

	var wait_msg = log.innerHTML+"Fetching druids...\n";
	var druid_each_callback = function(i, s) { report_model['druids'].push(s); log.innerHTML = log.innerHTML+"druid:"+s+"\n"; };
	var preprocessing_callback = function() {log.innerHTML='';};
	get_druids_req(log, wait_msg, druid_each_callback, preprocessing_callback);
}

function show_buttons() {
	$('#updates').show(400);
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

document.addEventListener("turbo:load", () => {
  $('#get_druids').on('click', get_druids)
	$('#paste-druids-button').on('click', () => $('#pid_list').show(400))
	$('#set-object-rights-button').on('click', () => $('#rights').show(400))
	$('#set-collection-button').on('click', () => $('#set_collection').show(400))

	$('#confirm-set-collection-button').on('click', () => {
		fetch_druids(set_collection)
		$('#set_collection').hide(400)
	})

	$('#rights_button').on('click', () => {
			fetch_druids(set_rights)
			$('#rights').hide(400)
	})

	$('#stop').on('click', () => stop_all())
})

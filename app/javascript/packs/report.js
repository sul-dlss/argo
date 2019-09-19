import 'jquery'
require('free-jqgrid')

/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.

$(document).ready(function() {
  const colModel = report_model.column_model;
  colModel[1]['formatter'] = (val, opts, row) => `<a href='${val}' target='_blank'>${val}</a>`;

  let initialized = false;
  $('#report_grid').jqGrid({
    url: report_model.data_url,
    rownumbers: true,
    datatype: 'json',
    pager: 'preport_grid',
    colModel: report_model.column_model,
    sortable: true,
    jsonReader: {
      repeatitems: false,
      root: 'rows'
    },
    scroll: 1,
    prmNames: {
      npage: 'npage'
    },
    viewrecords: true,
    recordtext: '{2} records',
    gridComplete() {
      if (!initialized) {
        $(window).trigger('resize');
        return initialized = true;
      }
    }
  });

  $('#report_grid').jqGrid('navGrid', '#preport_grid', {
    add:false,
    edit:false,
    del:false,
    search:false,
    refresh:true
  }
  );

  $('#report_grid').jqGrid('navButtonAdd', '#preport_grid', {
    caption: "Columns",
    title: "Choose Columns",
    buttonicon: 'ui-icon-script',
    onClickButton() { return $('#report_grid').jqGrid('columnChooser', {
      done(stuff) { return (
        this.resize()
      ); }
    }); }
  }
  );

  $('#report_grid').jqGrid('navButtonAdd', '#preport_grid', {
    caption: "Download",
    title: "Download as CSV",
    buttonicon: 'ui-icon-disk',
    onClickButton() {
      const visible = $.grep($('#report_grid').jqGrid('getGridParam','colModel'), (col,idx) => (col.name !== 'rn') && !col.hidden);
      const field_list = $.map(visible, (col,idx) => col.name).join(',');
      return $("body").append(`<iframe src='${report_model.download_url}&fields=${field_list}' style='display: none;' ></iframe>`);
    }
  }
  );

  const resized = function() {
    $('#report_grid').jqGrid('setGridHeight', $(window).innerHeight() - ($('#report_container').offset().top + 90));
    return $('#report_grid').jqGrid('setGridWidth',  $('#appliedParams').outerWidth());
  };

  let resize_timeout = null;
  $(window).bind('resize', () => {
    if (resize_timeout) {
      clearTimeout(resize_timeout);
    }
    return resize_timeout = setTimeout(resized, 200);
  });

  return resized();
});

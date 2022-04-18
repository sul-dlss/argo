import { Controller } from "stimulus"
import DorRegistration from '../registration/register'

export default class extends Controller {
  static targets = ["lockButton", "unlockButton", "gridShowLabel", "textShowLabel"]

    connect() {
        this.rc = this.createRegistrationContext()
    }

    lock(event) {
        this.toggleEditing(false)
    }

    unlock(event) {
        this.toggleEditing(true)
    }

    addRow(column_data) {
        this.addRowWithData([])
    }

    deleteRows(event) {
        const selection = $('#data').jqGrid('getGridParam','selarrrow');
        for (let i = selection.length-1; i >= 0; i--) {
          $('#data').jqGrid('delRowData',selection[i]);
        }
    }

    resetDialog() {
        const modalElement = document.getElementById('resetModal')
        bootstrap.Modal.getOrCreateInstance(modalElement).show()

        $('#resetModal [data-action="reset"]').on('click', () => this.reset())
    }

    register() {
        var cells = $('#data').jqGrid('getGridParam','savedRow');
        if (cells.length > 0) {
          this.rc.displayRequirements('You are still editing a cell. Please use tab or enter to finish editing before trying to register items.')
          return;
        }
        else{
          if (this.allValid()) {
            this.toggleEditing(false);
            this.rc.registerAll();
          } else {
            this.rc.displayRequirements('The form contains errors. Please correct them before submitting.')
          }
        }
    }

    trackingSheet() {
        this.stopEditing(true);
        this.rc.getTrackingSheet($('#data').getCol('druid'));
    }

    enableGridView() {
        this.textToGrid();
        this.gridShowLabelTarget.classList.add("ui-state-active")
        this.textShowLabelTarget.classList.remove("ui-state-active")

        $('#id_list').hide();
        this.element.querySelectorAll('button').forEach((button) => button.disabled = false)
    }

    enableTextView() {
        this.stopEditing(true);
        this.gridToText();
        this.resizeIdList();
        $('#id_list').show();
        this.textShowLabelTarget.classList.add("ui-state-active")
        this.gridShowLabelTarget.classList.remove("ui-state-active")
        this.element.querySelectorAll('button').forEach((button) => button.disabled = true)
    }

    // private methods

    resizeIdList() {
        const boxHeight = Math.max($('#gbox_data .ui-jqgrid-bdiv').height(), 150)
        $('#id_list').animate({
          'top': $('#gbox_data .ui-jqgrid-hdiv').position().top + 3,
          'left': 3,
          'width': $('#gbox_data .ui-jqgrid-bdiv').width() - 4,
          'height' : $('#gbox_data .ui-jqgrid-hdiv').height() + boxHeight - 4
        }, 0);
    }

    formatDruids(index) {
        var rowCount = $('#data').jqGrid('getGridParam','reccount');
        var checkRow = function(i) {
          var rowData = $('#data').jqGrid('getRowData',i);
          rowData.druid = rowData.druid.trim().replace(/^.+:/,'')
          $('#data').jqGrid('setRowData',i,rowData);
        }
        if (typeof index == 'undefined') {
          for (var i = 0; i < rowCount; i++) {
            checkRow(i)
          }
        } else {
          checkRow(index)
        }
      }

    addIdentifiers(identifiers) {
        identifiers.map((newId) => {
          if (newId.trim() != '') {
            var params = newId.split('\t');
            this.addRowWithData(params);
          }
        })
      }

      textToGrid() {
        $('#data').jqGrid('clearGridData');
        $('#data').data('nextId',0);
        var textData = $('#id_list').val().replace(/^\t*\n$/,'');
        this.addIdentifiers(textData.split('\n'));
        this.formatDruids();
      }

      gridToText() {
        var text = '';
        var gridData = $('#data').jqGrid('getRowData');
        for (var i = 0; i < gridData.length; i++) {
          var rowData = gridData[i];
          text += [rowData.barcode_id, rowData.metadata_id, rowData.source_id, rowData.druid, rowData.label].join("\t") + "\n"
        }
        $('#id_list').val(text);
      }

    allValid() {
        return $('#properties .invalid').length == 0 && $('#data .invalid').length == 0
    }

    reset() {
        this.rc = this.createRegistrationContext()
        $('#data').jqGrid('clearGridData');
        this.toggleEditing(true);
    }

    createRegistrationContext() {
        var progressStep = 1;
        var currentStep = 0;
        return new DorRegistration({
          setStatus : function(data, status) {
            data.status = status;
            return $('#data').jqGrid('setRowData', data.id, data);
          },
          getDataIds : function() {
            return $('#data').jqGrid('getDataIDs');
          },
          getData : function(rowid) {
            return $('#data').jqGrid('getRowData',rowid);
          },
          progress : function(init) {
            if (init) {
              var numItems = $('#data').jqGrid('getDataIDs').length;
              progressStep = 100 / numItems;
              currentStep = 0;
              this.progressDialog(numItems)
            } else {
              currentStep += progressStep;
              document.getElementById('register-progress').value = currentStep
              if (currentStep >= 99.999) { $('#progressModal').modal('hide') }
            }
          },
          displayRequirements : function(text) {
            document.querySelector('#gridErrorModal .modal-body p').innerHTML = text;

            const myModal = new bootstrap.Modal(document.getElementById('gridErrorModal'), {})
            myModal.show()
          },
          progressDialog : function(numItems) {
            // Bootstrap 5 will be like this:
            // var myModal = new bootstrap.Modal(document.getElementById('progressModal'), {})
            // myModal.show()

            document.querySelector('#progressModal .modal-title').innerHTML = `Registering ${numItems} items`;
            $('#progressModal').modal({ show: true })
          }
        });
      }

    addRowWithData(column_data) {
        var newId = $('#data').data('nextId') || 0;
        var newRow = { id: newId };
        var columns = $('#data').jqGrid('getGridParam','colModel');

        for (var i = 2; i < columns.length; i++) {
            var value = this.processValue(columns[i].name, column_data[i-2]);
            newRow[columns[i].name] = value;
        }
        $('#data').jqGrid('addRowData',newId, newRow, 'last');
        $('#data').jqGrid('setRowData',newId, newRow);
        $('#data').data('nextId',newId+1)
    }

    // Strip leading and trailing punctuation from everything but label
    processValue(cellname, value) {
        if (value) {
            if (cellname == 'label')
            return value.trim();
            else
            return value.replace(/(^[^a-zA-Z0-9]+|[^a-zA-Z0-9]+$)/g,"");
        } else {
            return ''
        }
    }

    toggleEditing(edit) {
        this.stopEditing(true);
        $('#data').jqGrid('setColProp','source_id',{ editable: edit });
        $('#data').jqGrid('setColProp','metadata_id',{ editable: edit });
        $('#data').jqGrid('setColProp','barcode_id',{ editable: edit });
        $('#data').jqGrid('setColProp','druid',{ editable: edit }); //, formatter: edit ? null : druidFormatter });
        $('#data').jqGrid('setColProp','label',{ editable: edit });

        this.lockButtonTarget.hidden = !edit
        this.unlockButtonTarget.hidden = edit
      }

      stopEditing(autoSave) {
        var cells = $('#data').jqGrid('getGridParam','savedRow');
        if (cells.length > 0) {
          var method = autoSave ? 'saveCell' : 'restoreCell';
          $('#data').jqGrid(method,cells[0].id,cells[0].ic);
        }
      }
}

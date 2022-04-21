import { Controller } from "stimulus"
import DorRegistration from '../registration/register'

export default class extends Controller {
  static targets = ["gridShowLabel", "textShowLabel"]

    connect() {
        this.rc = this.createRegistrationContext()
    }

    addRow(column_data) {
        this.addRowWithData([])
    }

    deleteRows(event) {
      $('#data').jqGrid('delRowData', event.target.closest("tr.jqgrow").id);
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

        document.querySelector('.ui-jqgrid-hdiv').hidden = false
        document.querySelector('.ui-jqgrid-bdiv').hidden = false
        document.querySelector('#id_list').hidden = true
        this.element.querySelectorAll('button').forEach((button) => button.disabled = false)
    }

    enableTextView() {
        if (this.textShowLabelTarget.classList.contains("ui-state-active"))
          return // Already in this state.

        this.stopEditing(true);
        this.gridToText();
        this.resizeIdList();
        document.querySelector('.ui-jqgrid-hdiv').hidden = true
        document.querySelector('.ui-jqgrid-bdiv').hidden = true
        document.querySelector('#id_list').hidden = false

        this.textShowLabelTarget.classList.add("ui-state-active")
        this.gridShowLabelTarget.classList.remove("ui-state-active")
        this.element.querySelectorAll('button').forEach((button) => button.disabled = true)
    }

    // private methods

    resizeIdList() {
        const gridHeight = document.querySelector('.ui-jqgrid-bdiv').getBoundingClientRect().height + 23
        document.querySelector('#id_list').style.height = `${gridHeight}px`
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
            const params = newId.split('\t');
            this.addRowWithData(params);
          }
        })
    }

    textToGrid() {
        $('#data').jqGrid('clearGridData');
        $('#data').data('nextId',0);
        const textData = $('#id_list').val().replace(/^\t*\n$/,'');
        this.addIdentifiers(textData.split('\n'));
        this.formatDruids();
    }

    gridToText() {
        var text = '';
        var gridData = $('#data').jqGrid('getRowData');
        for (var i = 0; i < gridData.length; i++) {
          const rowData = gridData[i];
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
            const myModal = new bootstrap.Modal(document.getElementById('progressModal'), {})
            myModal.show()
          }
        });
      }

    addRowWithData(column_data) {
        var newId = $('#data').data('nextId') || 0;
        var newRow = { id: newId };
        var columns = $('#data').jqGrid('getGridParam','colModel');
        columns.filter(column => column.label != ' ').forEach((column, index) => {
          newRow[column.name] = this.processValue(column.name, column_data[index]);
        })

        $('#data').jqGrid('addRowData', newId, newRow, 'last');
        $('#data').jqGrid('setRowData', newId, newRow);
        $('#data').data('nextId', newId+1)
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
        document.querySelector("#tracking-sheet-btn").disabled = edit;
      }

      stopEditing(autoSave) {
        var cells = $('#data').jqGrid('getGridParam','savedRow');
        if (cells.length > 0) {
          var method = autoSave ? 'saveCell' : 'restoreCell';
          $('#data').jqGrid(method,cells[0].id,cells[0].ic);
        }
      }
}

import bootstrap from "bootstrap/dist/js/bootstrap";
import qs from "qs";
import { Controller } from "@hotwired/stimulus";
import { TabulatorFull as Tabulator } from "tabulator-tables";

export default class extends Controller {
  static targets = ["columnSelector"];

  static values = {
    dataUrl: String,
    dataUrlParams: Object,
    downloadUrl: String,
    columnModel: Array,
  };

  connect() {
    this.table = new Tabulator("#objectsTable", {
      layout: "fitDataTable",
      height: "70vh",
      addRowPos: "bottom", //when adding a new row, add it to the bottom of the table
      movableColumns: true, //allow column order to be changed
      progressiveLoad: "scroll", //enable progressive loading
      columns: this.columnModelValue,
      ajaxURL: this.dataUrlValue,
      ajaxParams: this.dataUrlParamsValue,
    });
  }

  downloadCSV(event) {
    event.target.disabled = true;
    this.table.alert("Your CSV report is being generated. Please hold...");

    fetch(`${this.downloadUrlValue}?${this.downloadQueryParams()}`)
      .then((response) => {
        const reader = response.body.getReader();
        return new ReadableStream({
          start(controller) {
            return pump();
            function pump() {
              return reader.read().then(({ done, value }) => {
                // When no more data needs to be consumed, close the stream
                if (done) {
                  controller.close();
                  return;
                }
                // Enqueue the next data chunk into our target stream
                controller.enqueue(value);
                return pump();
              });
            }
          },
        });
      })
      .then((stream) => new Response(stream))
      .then((response) => response.blob())
      .then((blob) => URL.createObjectURL(blob))
      .then((href) => {
        const anchor = document.createElement("a");
        anchor.href = href;
        anchor.setAttribute("download", "report.csv");
        anchor.setAttribute("target", "_blank");
        anchor.click();
        URL.revokeObjectURL(href);
      })
      .catch((error) => {
        console.error(error);
      })
      .finally(() => {
        event.target.disabled = false;
        this.table.clearAlert();
      });
  }

  downloadQueryParams() {
    return qs.stringify({
      ...this.dataUrlParamsValue,
      fields: this.visibleFieldsAsString(),
    });
  }

  visibleFieldsAsString() {
    return this.table.columnManager.columns
      .filter((column) => column.visible)
      .map((column) => column.field)
      .join(",");
  }

  openColumnSelectorModal(event) {
    event.preventDefault();
    bootstrap.Modal.getOrCreateInstance(this.columnSelectorTarget).show();
  }

  toggleColumn(event) {
    const columnName = event.target.name;

    if (event.target.checked) {
      this.table.showColumn(columnName);
    } else {
      this.table.hideColumn(columnName);
    }
  }
}

import { Controller } from 'stimulus'

export default class extends Controller {
  // When a user selects a spreadsheet file for uploading via the bulk metadata upload function,
  // this function is called to verify the filename extension.
  fileChanged(event) {
    const filename = event.target.value.toLowerCase()
    const warning = this.element.querySelector('#bulk-spreadsheet-warning')
    warning.innerHTML = ''

    // Use lastIndexOf() since endsWith() is part of the latest ECMAScript 6 standard and not implemented
    // in Poltergeist/PhantomJS yet.
    if (!(filename.endsWith(".xlsx") || filename.endsWith(".xls") || filename.endsWith(".xml") || filename.endsWith(".csv")))
        warning.innerHTML= 'Note: Only spreadsheets or XML files are allowed. Please check your selected file.'

  }
}

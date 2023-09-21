import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static targets = ['submit', 'file', 'radio', 'note']
  // When a user selects a spreadsheet file for uploading via the bulk metadata upload function,
  // this function is called to verify the filename extension.
  fileChanged (event) {
    const filename = event.target.value.toLowerCase()
    const warning = this.element.querySelector('#bulk-spreadsheet-warning')
    warning.innerHTML = ''

    // Use lastIndexOf() since endsWith() is part of the latest ECMAScript 6 standard and not implemented
    // in Poltergeist/PhantomJS yet.
    if (!(filename.endsWith('.xlsx') || filename.endsWith('.xls') || filename.endsWith('.xml') || filename.endsWith('.csv'))) { warning.innerHTML = 'Note: Only spreadsheets or XML files are allowed. Please check your selected file.' } else { this.enableControls() }
  }

  // Enable everything except for the submit button upon file upload
  enableControls () {
    this.radioTargets.forEach((ctrl) => ctrl.removeAttribute('disabled'))
    this.noteTarget.disabled = false
  }

  enableSubmit () {
    this.submitTarget.disabled = false
  }

  connect () {
    // Resize the modal
    const classes = this.element.closest('.modal-dialog').classList
    classes.remove('modal-xl')
    classes.add('modal-lg')

    // None of the form controls should be functional until a file has been
    // selected
    this.radioTargets.forEach((ctrl) => ctrl.setAttribute('disabled', true))
    this.noteTarget.disabled = true
    this.submitTarget.disabled = true
  }
}

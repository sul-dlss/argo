import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static targets = ['titleWarning', 'catalogRecordId', 'catalogRecordIdWarning', 'catalogRecordIdFormatError', 'createCollectionFields', 'catalogRecordIdFields']

  revealCreateCollection () {
    this.createCollectionFieldsTarget.hidden = false
    this.catalogRecordIdFieldsTarget.hidden = true
  }

  revealCreateCollectionCatalogRecordId () {
    this.createCollectionFieldsTarget.hidden = true
    this.catalogRecordIdFieldsTarget.hidden = false
  }

  checkTitle (event) {
    fetch(`/collections/exists?title=${event.target.value}`)
      .then(resp => resp.json())
      .then(data => {
        this.titleWarningTarget.hidden = !data
      })
  }

  checkCatalogRecordId (event) {
    this.catalogRecordIdFormatErrorTarget.hidden = !this.catalogRecordIdTarget.validity.patternMismatch
    fetch(`/collections/exists?catalog_record_id=${event.target.value}`)
      .then(resp => resp.json())
      .then(data => {
        this.catalogRecordIdWarningTarget.hidden = !data
      })
  }
}

import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static targets = ['titleWarning', 'catalogRecordId', 'catalogRecordIdWarning', 'catalogRecordIdFormatError', 'createCollectionFields', 'catalogRecordIdFields', 'catalogRecordDoesNotExistWarning']

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

  async checkCatalogRecordId (event) {
    if (this.catalogRecordIdTarget.validity.patternMismatch) {
      this.catalogRecordIdFormatErrorTarget.hidden = false
      return
    }

    this.catalogRecordIdFormatErrorTarget.hidden = true
    await fetch(`/collections/exists?catalog_record_id=${event.target.value}`)
      .then(resp => resp.json())
      .then(data => {
        this.catalogRecordIdWarningTarget.hidden = !data
      })

    await fetch(`/registration/catalog_record_id?catalog_record_id=${event.target.value}`)
      .then(resp => resp.json())
      .then(data => {
        this.catalogRecordDoesNotExistWarningTarget.hidden = data
      })
  }
}

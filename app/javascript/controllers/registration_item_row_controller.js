import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static targets = ['barcode', 'catalogRecordId', 'sourceId', 'label']
  static values = {
    csv: Boolean
  }

  connect () {
    // These validations need to be run after values are pasted in, unless the form was loaded in CSV mode
    if (!this.csvValue) {
      this.validateCatalogRecordId()
      this.validateSourceId()
      this.validateBarcode()
      this.validateLabel()
    }
  }

  // Mark any duplicate sourceIds as invalid
  validateSourceId (event) {
    const field = this.sourceIdTarget
    const currentSourceId = field.value
    if (currentSourceId === '') { return }

    if (field.validity.patternMismatch) {
      field.classList.toggle('is-invalid', !field.validity.valid)
    } else if (this.isDuplicateSourceId(currentSourceId)) {
      this.setValidation(field, 'Duplicate source ID on this form')
      field.classList.add('is-invalid')
    } else {
      this.clearValidation(field) // all other checks passed

      // Check to see if this is unique in SDR
      fetch(`/registration/source_id?source_id=${currentSourceId}`)
        .then(response => response.json())
        .then((data) => {
          if (data) {
            this.setValidation(field, 'Duplicate source ID')
          } else {
            this.clearValidation(field)
          }
          field.classList.toggle('is-invalid', !field.validity.valid)
        })
    }
  }

  validateBarcode () {
    const field = this.barcodeTarget
    if (field.validity.patternMismatch) {
      field.classList.toggle('is-invalid', !field.validity.valid)
    } else {
      this.clearValidation(field)
    }
  }

  // Check that catalog record ID exists.
  validateCatalogRecordId () {
    const field = this.catalogRecordIdTarget
    const currentCatalogRecordId = field.value
    if (currentCatalogRecordId === '') { return }

    if (field.validity.patternMismatch) {
      field.classList.toggle('is-invalid', !field.validity.valid)
    } else {
      // Only check if the format is valid
      this.clearValidation(field)

      // Check to see if this is unique in SDR
      fetch(`/registration/catalog_record_id?catalog_record_id=${currentCatalogRecordId}`)
        .then(response => {
          if (response.ok) {
            return response.json()
          }
          throw new Error('Cannot check catalog record ID. Try again later.')
        })
        .then((data) => {
          if (!data) {
            this.setValidation(field, 'Not found in catalog')
          }
          field.classList.toggle('is-invalid', !field.validity.valid)
        })
        .catch((error) => {
          this.setValidation(field, error.message)
        })
    }
  }

  validateLabel () {
    const field = this.labelTarget
    if (this.catalogRecordIdTarget.value === '') {
      field.required = true
    } else {
      field.required = false
      field.classList.toggle('is-invalid', false)
    }
  }

  setValidation (field, msg) {
    field.setCustomValidity(msg)
    field.reportValidity()
  }

  clearValidation (field) {
    this.setValidation(field, '')
  }

  isDuplicateSourceId (currentSourceId) {
    // Find all of the sourceId nodes on the page
    const nodes = document.querySelectorAll('[data-registration-target="sourceId"]')
    const existingSourceIds = Array.from(nodes).map((target) => target.value)
    const matching = existingSourceIds.filter((elem) => elem === currentSourceId)
    return matching.length > 1
  }
}

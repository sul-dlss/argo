import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static targets = ['barcode', 'catalogRecordId', 'sourceId', 'label']
  static values = {
    csv: Boolean
  }

  connect () {
    if (!this.csvValue) {
      this.setLabelRequired()
    }
  }

  // Mark any duplicate sourceIds as invalid
  validateSourceId (event) {
    const field = this.sourceIdTarget
    const currentSourceId = field.value
    if (currentSourceId === '') { return }

    if (field.validity.patternMismatch) {
      field.reportValidity()
    } else if (this.isDuplicateSourceId(currentSourceId)) {
      this.setValidation(field, 'Duplicate source ID on this form')
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
        })
    }
  }

  validateBarcode () {
    const field = this.barcodeTarget
    if (field.validity.patternMismatch) {
      field.reportValidity()
    } else {
      this.clearValidation(field)
    }
  }

  // Check that catalog record ID exists.
  validateCatalogRecordId () {
    this.setLabelRequired()
    const field = this.catalogRecordIdTarget
    const currentCatalogRecordId = field.value
    if (currentCatalogRecordId === '') { return }

    if (field.validity.patternMismatch) {
      this.setValidation(field, 'Incorrect format for HRID')
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
          } else {
            this.clearValidation(field)
          }
        })
        .catch((error) => {
          this.setValidation(field, error.message)
        })
    }
  }

  validateLabel () {
    this.labelTarget.reportValidity()
  }

  setLabelRequired () {
    const field = this.labelTarget
    if (this.catalogRecordIdTarget.value === '') {
      field.required = true
    } else {
      field.required = false
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

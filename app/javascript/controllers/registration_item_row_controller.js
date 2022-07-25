import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
    static targets = [ "barcode", "catkey", "sourceId" ]

    connect() {
      // These validations need to be run after values are pasted in.
      this.validateCatkey()
      this.validateSourceId()
      this.validateBarcode()
    }

    // Mark any duplicate sourceIds as invalid
    validateSourceId(event) {
        const field = this.sourceIdTarget
        const currentSourceId = field.value
        if (currentSourceId === '')
          return

        if (field.validity.patternMismatch) {
          field.classList.toggle("invalid", !field.validity.valid)
        } else if (this.isDuplicateSourceId(currentSourceId)) {
          this.setValidation(field, "Duplicate source ID on this form")
          field.classList.add("invalid")
        } else { 
          this.clearValidation(field) // all other checks passed

          // Check to see if this is unique in SDR
          fetch(`/registration/source_id?source_id=${currentSourceId}`)
            .then(response => response.json())
            .then((data) => {
                if (data) {
                this.setValidation(field, "Duplicate source ID")
                } else {
                this.clearValidation(field)
                }
                field.classList.toggle("invalid", !field.validity.valid)
            })
        }
    }

    validateBarcode() {
        const field = this.barcodeTarget
        if (field.validity.patternMismatch) {
          field.classList.toggle("invalid", !field.validity.valid)
        } else {
          this.clearValidation(field)
        }
    }

    // Check that catkey exists.
    validateCatkey() {
        const field = this.catkeyTarget
        const currentCatkey = field.value
        if (currentCatkey === '')
          return

        if (field.validity.patternMismatch) {
          field.classList.toggle("invalid", !field.validity.valid)
        } else {
          // Only check if the format is valid
          this.clearValidation(field)
  
          // Check to see if this is unique in SDR
          fetch(`/registration/catkey?catkey=${currentCatkey}`)
            .then(response => {
              if (response.ok) {
                return response.json();
              }
              throw new Error('Cannot check catkey. Try again later.');
            })
            .then((data) => {
              if (!data) {
                this.setValidation(field, "Not found in catalog")
              }
              field.classList.toggle("invalid", !field.validity.valid)
            })
            .catch((error) => {
              this.setValidation(field, error.message)
            })
        }
      }


    setValidation(field, msg) {
        field.setCustomValidity(msg)
        field.reportValidity()
    }
    
    clearValidation(field) {
      this.setValidation(field, '')
    }

    isDuplicateSourceId(currentSourceId) {
      // Find all of the sourceId nodes on the page
      const nodes = document.querySelectorAll('[data-registration-target="sourceId"]')
      const existingSourceIds = Array.from(nodes).map((target) => target.value)
      const matching = existingSourceIds.filter((elem) => elem == currentSourceId)
      return matching.length > 1
    }
}

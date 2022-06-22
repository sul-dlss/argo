import { Controller } from "stimulus"

export default class extends Controller {
    static targets = [ "sourceId" ]

    // If the field is marked as invalid, then show the invalid (bootstrap) style.
    displayValidation(event) {
      const field = event.target
      field.classList.toggle("invalid", !field.validity.valid)
    }

    // Mark any duplicate sourceIds as invalid
    validateSourceId(event) {
      const field = event.target
      const currentSourceId = field.value
      if (this.isDuplicateSourceId(currentSourceId)) {
        this.setValidation(field, "Duplicate source ID on this form")
        field.classList.add("invalid")
      } else if (!field.validity.patternMismatch) { // Only check if the format is valid
        this.clearValidation(field)

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

    isDuplicateSourceId(currentSourceId) {
      const existingSourceIds = this.sourceIdTargets.map((target) => target.value)
      const matching = existingSourceIds.filter((elem) => elem == currentSourceId)
      return matching.length > 1
    }

    setValidation(field, msg) {
      field.setCustomValidity(msg)
      field.reportValidity()
    }

    clearValidation(field) {
      field.setCustomValidity('')
      field.reportValidity()
    }

    // Check that catkey exists.
    validateCatkey(event) {
      const field = event.target
      const currentCatkey = field.value
      if (!field.validity.patternMismatch) { // Only check if the format is valid
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
    
}

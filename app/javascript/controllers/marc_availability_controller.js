import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static targets = ['status']
  static values = {
    catalogRecordId: String
  }

  connect () {
    if (this.catalogRecordIdValue === '') { return }

    fetch(`/registration/marc_record?catalog_record_id=${this.catalogRecordIdValue}`)
      .then(response => {
        if (response.ok) {
          return response.json()
        }
        throw new Error('Unable to check MARC availability')
      })
      .then((hasMarcRecord) => {
        if (!hasMarcRecord) {
          this.statusTarget.innerHTML = '<span class="badge bg-warning text-dark" title="MARC record not yet available in FOLIO. Metadata refresh will not be available until a MARC record is created.">⚠ No MARC</span>'
        } else {
          this.statusTarget.innerHTML = ''
        }
      })
      .catch(() => {
        this.statusTarget.innerHTML = '<span class="badge bg-secondary" title="Unable to check MARC availability">MARC check unavailable</span>'
      })
  }
}

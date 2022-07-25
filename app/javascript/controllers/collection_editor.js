import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static targets = [ "titleWarning", "catkeyWarning", "createCollectionFields", "catkeyFields" ]

  revealCreateCollection() {
    this.createCollectionFieldsTarget.hidden = false
    this.catkeyFieldsTarget.hidden = true
  }

  revealCreateCollectionCatkey() {
    this.createCollectionFieldsTarget.hidden = true
    this.catkeyFieldsTarget.hidden = false
  }

  checkTitle(event) {
    fetch(`/collections/exists?title=${event.target.value}`).
      then(resp => resp.json()).
      then(data => {
        this.titleWarningTarget.hidden = !data
      })
  }

  checkCatkey(event) {
    fetch(`/collections/exists?catkey=${event.target.value}`).
      then(resp => resp.json()).
      then(data => {
        this.catkeyWarningTarget.hidden = !data
      })
  }
}

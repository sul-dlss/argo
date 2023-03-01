import { Controller } from '@hotwired/stimulus'
import Sharing from '../modules/sharing'

// This handles the "Register APO" as well as "Edit APO" forms
// This controller should be on a <form> node
export default class extends Controller {
  static targets = [ "selectCollectionFields", "createCollectionFields", "catalogRecordIdFields" ]

  connect() {
    this.sharing = new Sharing(this.element.querySelector('sharing'))
    this.sharing.start()
  }

  submit() {
    this.sharing.serialize(this.element)
  }

  hideCollection() {
    this.selectCollectionFieldsTarget.hidden = true
    this.createCollectionFieldsTarget.hidden = true
    this.catalogRecordIdFieldsTarget.hidden = true
  }

  revealCreateCollection() {
    this.hideCollection()
    this.createCollectionFieldsTarget.hidden = false
  }

  revealCreateCollectionCatalogRecordId() {
    this.hideCollection()
    this.catalogRecordIdFieldsTarget.hidden = false
  }

  revealSelectCollection() {
    this.hideCollection()
    this.selectCollectionFieldsTarget.hidden = false
  }
}

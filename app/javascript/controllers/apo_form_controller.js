import { Controller } from 'stimulus'
import Sharing from '../modules/sharing'

// This handles the "Register APO" as well as "Edit APO" forms
// This controller should be on a <form> node
export default class extends Controller {
  static targets = [ "selectCollectionFields", "createCollectionFields", "catkeyFields",  ]

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
    this.catkeyFieldsTarget.hidden = true
  }

  revealCreateCollection() {
    this.hideCollection()
    this.createCollectionFieldsTarget.hidden = false
  }

  revealCreateCollectionCatkey() {
    this.hideCollection()
    this.catkeyFieldsTarget.hidden = false
  }

  revealSelectCollection() {
    this.hideCollection()
    this.selectCollectionFieldsTarget.hidden = false
  }
}

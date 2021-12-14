import { Controller } from 'stimulus'

export default class extends Controller {
  static targets = [ "titleWarning", "catkeyWarning" ]

  toggle(event) {
    $('.collection_div').hide()
    var reveal
    if (reveal = $(event.target).data('reveal')) {
      $(`#${reveal}`).show();
    }
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

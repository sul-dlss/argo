import { Controller } from 'stimulus'

export default class extends Controller {
  toggle(event) {
    $('.collection_div').hide()
    var reveal
    if (reveal = $(event.target).data('reveal')) {
      $(`#${reveal}`).show();
    }
  }
}

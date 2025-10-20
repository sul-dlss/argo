import * as renderjson from 'renderjson'
import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static targets = ['events', 'eventsSection']

  connect () {
    this.events = JSON.parse(this.eventsTarget.innerText)
    this.collapse()
  }

  expand () {
    this.eventsSectionTarget.replaceChildren(renderjson.set_show_to_level('all')(this.events))
  }

  collapse () {
    this.eventsSectionTarget.replaceChildren(renderjson.set_show_to_level(1)(this.events))
  }
}

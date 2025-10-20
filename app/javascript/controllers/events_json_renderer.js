import * as renderjson from 'renderjson'
import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static targets = ['events', 'eventsSection', 'toggle']

  connect () {
    this.event = JSON.parse(this.eventsTarget.innerText)[0]
    this.toggle()
  }

  toggle () {
    const isCollapsed = this.eventsSectionTarget.classList.contains('collapsed')
    if (isCollapsed) {
      this.eventsSectionTarget.classList.remove('collapsed')
      this.eventsSectionTarget.replaceChildren(renderjson.set_show_to_level('all')(this.event))
      this.toggleTarget.classList.remove('bi-plus')
      this.toggleTarget.classList.add('bi-dash')
    } else {
      this.eventsSectionTarget.classList.add('collapsed')
      this.eventsSectionTarget.replaceChildren(renderjson.set_show_to_level(1)(this.event))
      this.toggleTarget.classList.remove('bi-dash')
      this.toggleTarget.classList.add('bi-plus')
    }
  }
}

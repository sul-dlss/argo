import * as renderjson from 'renderjson'
import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static targets = ['section']
  static values = {
    cocina: Object
  }

  connect () {
    renderjson.set_icons('\uF4FC', '\uF2E8') // Bootstrap icons
    this.collapse()
  }

  expand (event) {
    if (event) event.preventDefault()
    this.sectionTarget.replaceChildren(renderjson.set_show_to_level('all')(this.cocinaValue))
  }

  collapse (event) {
    if (event) event.preventDefault()
    this.sectionTarget.replaceChildren(renderjson.set_show_to_level(1)(this.cocinaValue))
  }
}

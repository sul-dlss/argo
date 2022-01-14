import * as renderjson from 'renderjson'
import { Controller } from 'stimulus'

export default class extends Controller {
  static targets = ['cocina', 'section']

  connect() {
    this.cocina = JSON.parse(this.cocinaTarget.innerText)
    this.collapse()
  }

  expand() {
    this.sectionTarget.replaceChildren(renderjson.set_show_to_level('all')(this.cocina))
  }

  collapse() {
    this.sectionTarget.replaceChildren(renderjson.set_show_to_level(1)(this.cocina))
  }
}

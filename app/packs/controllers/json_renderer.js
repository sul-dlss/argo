import * as renderjson from 'renderjson'
import { Controller } from 'stimulus'

export default class extends Controller {
  static targets = ['cocina', 'section']

  connect() {
    const cocina = JSON.parse(this.cocinaTarget.innerText)
    this.sectionTarget.appendChild(renderjson.set_show_to_level(1)(cocina))
  }
}

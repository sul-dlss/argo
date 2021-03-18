import * as renderjson from 'renderjson'
import { Controller } from 'stimulus'

export default class extends Controller {
  static targets = ['section']

  connect() {
    const cocina = JSON.parse(this.sectionTarget.dataset.cocina)
    this.sectionTarget.appendChild(renderjson.set_show_to_level(1)(cocina))
  }
}

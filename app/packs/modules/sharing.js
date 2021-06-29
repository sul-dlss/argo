import PermissionList from 'modules/permission_list'
import PermissionAdd from 'modules/permission_add'

export default class {
    /**
     * This is the editor that allows you to manage permission grants to an object
     * @param element - The element that has a data-permissions attribute
     */
    constructor(element) {
        this.element = element
        this.rawData = JSON.parse(element.getAttribute('data-permissions'))

        this.list = new PermissionList(this)
        this.form = new PermissionAdd(this)
    }

    start() {
      this.root = document.createElement('p')
      this.element.appendChild(this.root)
      this.redraw()
      this.rawData.map((grant) => {
          this.add(grant)
      })
    }

    /**
     * Write out the form data as a series of hidden fields
     * removes any old serialized values before doing this in case any other
     * callback (e.g. validate) has prevented form submission.
     */
    serialize(form) {
      var id = 'serializedSharing'
      var elem = document.getElementById(id)
      if (elem != null) {
        elem.remove()
      }
      var newElem = document.createElement('span')
      newElem.id = 'serializedSharing'
      newElem.innerHTML = this.list.serialize()
      form.appendChild(newElem)
    }

    redraw() {
      this.element.removeChild(this.root)
      this.root = this.render()
      this.element.appendChild(this.root)
    }

    render() {
        var newElem = document.createElement('div')
        newElem.className = 'sharing'
        newElem.appendChild(this.form.render())
        newElem.appendChild(this.list.render())
        return newElem
    }

    // Something has happened that needs the view to redraw
    update() {
      this.redraw()
    }

    /**
     * Add data to the list
     */
    add(grant) {
      this.list.add(grant)
    }
}

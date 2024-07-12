export default class {
  /**
   * Represents the form widget for adding grants to an object
   * @param parent - The parent to which contains this element
   */
  constructor (parent) {
    this.parent = parent
  }

  rootElement () {
    const elem = document.createElement('fieldset')
    elem.className = 'mb-3 row'
    return elem
  }

  render () {
    const newEl = this.rootElement()
    newEl.innerHTML = '<legend class="col-sm-3">Add group<legend>'

    const div = document.createElement('div')
    div.className = 'col-sm-9 row'
    div.innerHTML = `<div class="col-lg-6"><input id="permissionName" class="form-control" placeholder="Group name"></div>
          <div class="col-lg-5">
            <select id="permissionRole" class="form-select"><option value="manage">Manage</option><option value="view">View</option></select>
          </div>
          <div class="col-lg-1">
            <button class="btn btn-primary">Add</button>
          </div>
          `

    const button = div.querySelector('button')
    button.addEventListener('click', (event) => {
      event.preventDefault()
      this.parent.add({
        name: document.getElementById('permissionName').value,
        type: 'group',
        access: document.getElementById('permissionRole').value
      })
    })

    newEl.appendChild(div)
    return newEl
  }
}

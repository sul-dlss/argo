export default class {
    /**
     * Represents the form widget for adding grants to an object
     * @param parent - The parent to which contains this element
     */
    constructor(parent) {
        this.parent = parent
    }

    rootElement() {
      var elem = document.createElement('fieldset')
      elem.className = 'form-group row'
      return elem
    }

    render() {
      var newEl = this.rootElement()
      newEl.innerHTML = '<legend class="col-sm-3">Add group<legend>'

      var div = document.createElement('div')
      div.className = "col-sm-9 form-inline"
      div.innerHTML = '<input id="permissionName" class="form-control" placeholder="Group name"/>' +
          '<select id="permissionRole" class="form-control"><option value="manage">Manage</option><option value="view">View</option></select>'

      var button = document.createElement('button')
      button.innerHTML = 'Add'
      button.className = 'btn btn-default'
      button.addEventListener('click', (event) => {
          event.preventDefault()
          this.parent.add({name: document.getElementById('permissionName').value, type: "group", access: document.getElementById('permissionRole').value}, )
      })

      div.appendChild(button)
      newEl.appendChild(div)
      return newEl
    }
}

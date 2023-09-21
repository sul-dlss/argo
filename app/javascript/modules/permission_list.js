import PermissionGrant from './permission_grant'

export default class {
  /**
     * Represents the list of all the permission grants on an object
     * @param parent - The parent to which contains this element
     */
  constructor (parent) {
    this.parent = parent
    this.data = []
  }

  rootElement () {
    const elem = document.createElement('table')
    elem.className = 'table'
    const thead = document.createElement('thead')
    thead.innerHTML = '<tr><th>Group name</th><th>Role</th><td></td></tr>'
    elem.appendChild(thead)
    return elem
  }

  render () {
    const newElement = this.rootElement()
    const tbody = document.createElement('tbody')
    newElement.appendChild(tbody)
    this.data.forEach((grant) => {
      tbody.appendChild(grant.render())
    })
    return newElement
  }

  // Remove a member of the list and re-render
  delete (item) {
    const index = this.data.indexOf(item)
    if (index > -1) {
      this.data.splice(index, 1)
    }
    this.parent.update()
  }

  /**
     * Add a new item to the parent
     * @param grant -- json including name, type and access
     */
  add (grant) {
    this.data.push(new PermissionGrant(this, grant))
    this.parent.update()
  }

  /**
     * Write out the data as hidden html fields
     */
  serialize () {
    return this.data.map((grant, index) => grant.serialize(index))
  }
}

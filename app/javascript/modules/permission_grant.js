export default class {
  /**
   * Represents a single permission grant on an object
   * @param list - The list to which contains this element
   * @param data - the hash that has the data this component represents
   */
  constructor (list, data) {
    this.list = list
    this.data = data
  }

  rootElement () {
    return document.createElement('tr')
  }

  render () {
    const element = this.rootElement()
    const button = document.createElement('button')
    button.innerHTML = 'Remove'
    button.className = 'btn btn-primary'
    button.addEventListener('click', (event) => {
      event.preventDefault()
      this.destroy()
    })
    element.innerHTML +=
      `<td class="permissionName">${this.data.name}</td>` +
      `<td class="permissionAccess">${this.data.access}</td>`
    const td = document.createElement('td')
    td.appendChild(button)
    element.appendChild(td)
    return element
  }

  /**
   * write out the row as a hidden html field
   */
  serialize (idx) {
    return (
      `<input type="hidden" name="apo[permissions][${idx}][name]" value="${this.data.name}">` +
      `<input type="hidden" name="apo[permissions][${idx}][access]" value="${this.data.access}">` +
      `<input type="hidden" name="apo[permissions][${idx}][type]" value="group">`
    )
  }

  destroy () {
    this.list.delete(this)
  }
}

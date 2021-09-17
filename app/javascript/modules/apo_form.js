import Sharing from './sharing'

export default class {
    /**
     * initialize the editor behaviors
     * @param {jQuery} element - The form that has a data-param-key attribute
     */
    constructor(element) {
        this.element = element
    }

    init() {
        this.collection()
        this.sharing()
    }

    sharing() {
      var sharing = new Sharing(this.element.find('sharing')[0])
      sharing.start()
      var form = this.element.closest('form')

      form.on('submit', () => {
          sharing.serialize(form[0])
      })
    }

    collection() {
      $('[name="apo_form[collection_radio]"]').on('change', (event) => {
        $('.collection_div').hide()
        var reveal
        if (reveal = $(event.target).data('reveal')) {
          $(`#${reveal}`).show();
        }
      })
    }
}

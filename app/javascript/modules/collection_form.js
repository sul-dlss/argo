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
    }

    collection() {
      $('[name="collection_radio"]').on('change', (event) => {
        $('.collection_div').hide()
        var reveal
        if (reveal = $(event.target).data('reveal')) {
          $(`#${reveal}`).show();
        }
      })
    }
}

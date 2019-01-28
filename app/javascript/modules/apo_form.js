import Sharing from 'modules/sharing'

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
        this.validate()
        this.sharing()
    }

    sharing() {
      var sharing = new Sharing(this.element.find('Sharing')[0])
      sharing.start()
      var form = this.element.closest('form')

      form.on('submit', () => {
          sharing.serialize(form[0])
      })
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

    // Initializes the validate script for the form that shows errors dynamically
    validate() {
        this.element.validate({
            rules: {
                title: "required"
            },
            messages: {
                title: ' &nbsp;&nbsp;Error:  A non-empty title is required.'
            },
            errorClass: 'apo-register-error',
            errorPlacement: function(error, element) {
                var errEltId = element.attr('id') + "-err-msg-elt";
                $("#"+errEltId).html(error.html());
                return true;
            },
            success: function(label) {
                //if we don't define this and return true, but we do define errorPlacement, the error messages never
                //disappear if the field goes valid.  not sure why that is.
                return true;
            }
        })
    }
}

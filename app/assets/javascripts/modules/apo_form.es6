export default class {
    /**
     * initialize the editor behaviors
     * @param {jQuery} element - The form that has a data-param-key attribute
     */
    constructor(element) {
        this.element = element
    }

    init() {
        this.validate()
    }

    // Initializes the validate script for the form that shows errors dynamically
    validate() {
        this.element.validate({
            rules: {
                title: "required",
                // is_valid_role_list is a REST endpoint in ApoController (i.e. /apo/is_valid_role_list)
                managers: {
                    remote: "is_valid_role_list"
                },
                viewers: {
                    remote: "is_valid_role_list"
                }
            },
            messages: {
                managers: 'Error:  Enter manager workgroup names as "stem:value", e.g., dlss:project-x.  Enter individuals as "sunetid:value".<br/><br/>',
                viewers: 'Error:  Enter viewer workgroup names as "stem:value", e.g., dlss:project-x.  Enter individuals as "sunetid:value".<br/><br/>',
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

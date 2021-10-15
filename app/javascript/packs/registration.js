import 'style/registration.scss'

import 'jquery'
import "bootstrap/dist/js/bootstrap"
import 'jquery.defaultText'
import 'jquery.textarea'
import 'free-jqgrid'
import 'registration/register'
import 'registration/grid'

// Start stimulus after free-jqgrid has been loaded
import { Application } from 'stimulus'
import RegistationController from 'controllers/registration_controller'
const application = Application.start()
application.register("registration", RegistationController)

import { Application } from 'stimulus'
import CollectionEditor from './collection_editor'
import BulkActions from './bulk_actions'
import BulkUpload from './bulk_upload'
import Button from './button'
import ContentTypeController from './content_type_controller'
import FacetFilter from './facet_filter'
import JSONRenderer from './json_renderer'
import Tokens from './tokens'
import WorkflowGrid from './workflow_grid_controller'
import BlacklightHierarchyController from 'blacklight-hierarchy/app/assets/javascripts/blacklight/hierarchy/blacklight_hierarchy_controller'
import NestedFormController from './nested_form_controller'
import RegistationController from './registration_controller'
import BulkUploadJobsController from './bulk_upload_jobs_controller'
import DateChoiceController from './date_choice_controller'
import ApoFormController from './apo_form_controller'
import OpenCloseController from './open_close_controller'
import StructuralController from './structural_controller'
import AccessRightsController from './access_rights_controller'
import ExpandableSnippets from './expandable_snippets'
import TagValidation from './tag_validation_controller'

const application = Application.start()
application.register("bulk-actions", BulkActions)
application.register("bulk-upload", BulkUpload)
application.register("button", Button)
application.register("content-type", ContentTypeController)
application.register("facet-filter", FacetFilter)
application.register('json-renderer', JSONRenderer)
application.register("workflow-grid", WorkflowGrid)
application.register("collection-editor", CollectionEditor)
application.register("tag-validation", TagValidation)
application.register("tokens", Tokens)
application.register("b-h-collapsible", BlacklightHierarchyController)
application.register("nested-form", NestedFormController)
application.register("registration", RegistationController)
application.register("bulk-upload-jobs", BulkUploadJobsController)
application.register("date-choice", DateChoiceController)
application.register("apo-form", ApoFormController)
application.register("open-close", OpenCloseController)
application.register("structural", StructuralController)
application.register("access-rights", AccessRightsController)
application.register("expandable-snippets", ExpandableSnippets)

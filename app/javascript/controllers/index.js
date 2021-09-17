import { Application } from 'stimulus'
import CollectionEditor from './collection_editor'
import BulkActions from './bulk_actions'
import BulkUpload from './bulk_upload'
import Button from './button'
import FacetFilter from './facet_filter'
import JSONRenderer from './json_renderer'
import Tokens from './tokens'
import WorkflowGrid from './workflow_grid_controller'
import BlacklightHierarchyController from 'blacklight-hierarchy/app/assets/javascripts/blacklight/hierarchy/blacklight_hierarchy_controller'
import NestedFormController from './nested_form_controller'

const application = Application.start()
application.register("bulk_actions", BulkActions)
application.register("bulk_upload", BulkUpload)
application.register("button", Button)
application.register("facet-filter", FacetFilter)
application.register('json-renderer', JSONRenderer)
application.register("workflow-grid", WorkflowGrid)
application.register("collection-editor", CollectionEditor)
application.register("tokens", Tokens)
application.register("b-h-collapsible", BlacklightHierarchyController)
application.register("nested-form", NestedFormController)

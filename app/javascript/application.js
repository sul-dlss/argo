// Entry point for the build script in your package.json

import "jquery"; // Blacklight 7 needs jQuery. Remove when we upgrade to Blacklight 8?
import bootstrap from "bootstrap/dist/js/bootstrap";
global.bootstrap = bootstrap; // Required for Blacklight 7 so it can manage the modals

import "blacklight-frontend/app/assets/javascripts/blacklight/blacklight";
import "./controllers";

import Argo from "./argo";

document.addEventListener("turbo:load", async () => {
  // Start argo after Turbo has been loaded
  new Argo().initialize();
});
import "@hotwired/turbo-rails";

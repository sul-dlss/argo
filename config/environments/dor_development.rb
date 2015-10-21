cert_dir = File.expand_path(File.join(File.dirname(__FILE__),"../certs"))

Dor.configure do
  ssl do
    cert_file File.join(cert_dir, Settings.SSL.CERT_FILE)
    key_file File.join(cert_dir, Settings.SSL.KEY_FILE)
    key_pass Settings.SSL.KEY_PASS
  end

  fedora do
    url Settings.FEDORA_URL
  end

  workflow do
    url Settings.WORKFLOW_URL
  end

  dor_services do
    url Settings.DOR_SERVICES_URL
  end

  solrizer.url Settings.SOLRIZER_URL

  suri do
    mint_ids     Settings.SURI.MINT_IDS
    id_namespace Settings.SURI.ID_NAMESPACE
    url          Settings.SURI.URL
    user         Settings.SURI.USER
    pass         Settings.SURI.PASS
  end

  metadata do
    exist.url   Settings.METADATA.EXIST_URL
    catalog.url Settings.METADATA.CATALOG_URL
  end

  content do
    content_user     Settings.CONTENT.USER
    content_base_dir Settings.CONTENT.BASE_DIR
    content_server   Settings.CONTENT.SERVER_HOST
  end

  stacks do
    document_cache_storage_root Settings.STACKS.DOCUMENT_CACHE_STORAGE_ROOT
    document_cache_host         Settings.STACKS.DOCUMENT_CACHE_HOST
    document_cache_user         Settings.STACKS.DOCUMENT_CACHE_USER
    local_workspace_root        Settings.STACKS.LOCAL_WORKSPACE_ROOT
    storage_root                Settings.STACKS.STORAGE_ROOT
    host                        Settings.STACKS.HOST
    user                        Settings.STACKS.USER
  end

  sdr do
    url Settings.SDR_URL
  end
end

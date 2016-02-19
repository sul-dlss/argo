# at present, we only use squash in -test and -prod.  but it has to
# be configured to be disabled if we don't configure it with an api
# key (which we don't have for dev).
Squash::Ruby.configure api_host: Settings.SQUASH.API_HOST,
                       api_key: Settings.SQUASH.API_KEY,
                       environment: Settings.SQUASH_ENVIRONMENT || Rails.env,
                       disabled: Settings.SQUASH.DISABLE,
                       revision_file: File.join(Rails.root, 'REVISION')

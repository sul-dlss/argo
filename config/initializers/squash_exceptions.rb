Squash::Ruby.configure api_host: Settings.SQUASH.API_HOST,
                       api_key: Settings.SQUASH.API_KEY,
                       environment: Settings.SQUASH_ENVIRONMENT || Rails.env,
                       disabled: Settings.SQUASH.DISABLE

[![CircleCI](https://circleci.com/gh/sul-dlss/argo.svg?style=svg)](https://circleci.com/gh/sul-dlss/argo)
[![Test Coverage](https://codecov.io/github/sul-dlss/argo/graph/badge.svg?token=7pyTZlYDip)](https://codecov.io/github/sul-dlss/argo)
[![GitHub version](https://badge.fury.io/gh/sul-dlss%2Fargo.svg)](https://badge.fury.io/gh/sul-dlss%2Fargo)

# Argo

Argo is the administrative interface to the Stanford Digital Repository.

## Installation

### System Requirements

1. Install Docker
2. Install Ruby

### Check Out the Code

```bash
git clone https://github.com/sul-dlss/argo.git
cd argo
```

### Run bundler to install the Gem dependencies

```bash
bundle install
```

## Local Development TL;DR

Brings up app at localhost:3000 with some test data:

```
yarn install
docker compose up -d
bin/rails db:prepare
bin/dev
bin/rake argo:seed_data # run in separate terminal window
rdbg -A # run in separate terminal window
```

## Run the tests locally

CI runs a series of steps;  this the sequence to do it locally, along with some helpful info.

1. **Pull down the latest docker containers**

    ```
    docker compose pull
    ```

2. **Start up the docker services needed for testing**

    Once everything has been successfully pulled, start up the docker services needed for testing (all but the web container)

    ```
    docker compose up -d
    ```

3. **Install Chrome**

    You will need to have Google Chrome browser installed, as the tests use chrome for a headless browser.

4. **Prepare rails for testing**

    ```
    bin/rails db:prepare test:prepare
    ```

5. **Run the linters and the tests**

    ```
    bin/rake
    ```

To run just the linters, run `bin/rake lint`. To run the linters individually, run `bundle exec erb_lint --lint-all`, `bundle exec rubocop`, and `bundle exec rake jslint`


## Recommended Local Development

Be sure all of the docker containers for dependent services are running in the background (e.g. solr, DSA) and stop the web container:

```
docker compose up -d
```

Create/prepare the dev/test databases:

```
bin/rails db:prepare
```

Start the development server - this should give you the Argo app on port 3000 mocking an admin login:

```
bin/dev
```

Most of the time (unless you already have data), you will want seed data and a single item.  Note tha all servers must be running first, including web, and this will clear solr:

```
bin/rake argo:seed_data
```

For creating additional test data, see the section below "Creating fixture data".

The webserver process is configured to run a remote debug session. You may attach (`-A`) the debugger in another terminal window:

```
rdbg -A
```

### System tests

To run a headed browser, set the `NO_HEADLESS` env variable. For example:

```
NO_HEADLESS=1 bundle exec rspec spec/system/item_view_spec.rb
```

## Creating fixture data

To begin registering items in the Argo UI, there will need to be at least one agreement object and one APO object in the index. To create and index one of each of these objects, run the following command:

```
bin/rails db:seed
```

or if running on the docker container:

```
docker compose exec web bin/rails db:seed
```

To get these objects, in addition to a single item object (useful for development purposes), run this command (assumes local rails server):

```
bin/rake argo:seed_data
```

To register an arbitrary number of test item objects, specify the number you want:

```
bin/rake argo:register_items[1]
```

Note that in all cases, you will need a web server of some kind running (either in web docker container or a local rails server).  Also note that creating the seed data will clear the existing Solr instance out (and you will have to confirm this).

## Internals

Argo uses Blacklight and Solr to expose the repository contents, and `dor-services-app` to enable editing and updating. Its key components include:

- Rails
- Blacklight
- dor-services-client
- RSolr
- Sidekiq
- Bootstrap

and in development or testing mode:

- RSpec
- Capybara
- Chrome

## Solr configuration
The Solr configuration is https://github.com/sul-dlss/sul-solr-configs/tree/master/argo_prod

To update this configuration, see the [README](https://github.com/sul-dlss/sul-solr-configs#updating-configurations).

When this configuration is updated, the configuration in `solr_conf/` should also be updated for Argo testing using a Solr container.

## Background Job Workers (in deployed environments)

Argo uses systemd to manage and monitor its Sidekiq-based background job workers in all deployed environments. See  [Sidekiq via systemd](https://github.com/sul-dlss/dlss-capistrano#sidekiq-via-systemd)

## Reset Process (for QA/Stage)

### Steps

1. [Reset the database](https://github.com/sul-dlss/DeveloperPlaybook/blob/main/best-practices/db_reset.md)
2. Clear the bulk directory: `rm -fr /workspace/bulk/*`

## Further reading

### Profiling

For information on how to profile the app in the event of performance issues, see [PROFILING.md](PROFILING.md).  This explains how to collect profiling info, how to analyze it, how to approach the issue generally, and alternatives/complements to Argo's main built-in profiling tool.

[![Build Status](https://travis-ci.org/sul-dlss/argo.png?branch=master)](https://travis-ci.org/sul-dlss/argo)
[![Code Climate](https://codeclimate.com/github/sul-dlss/argo/badges/gpa.svg)](https://codeclimate.com/github/sul-dlss/argo)
[![Code Climate Test Coverage](https://codeclimate.com/github/sul-dlss/argo/badges/coverage.svg)](https://codeclimate.com/github/sul-dlss/argo/coverage)
[![GitHub version](https://badge.fury.io/gh/sul-dlss%2Fargo.svg)](https://badge.fury.io/gh/sul-dlss%2Fargo)

# Argo

Argo is the administrative interface to the Stanford Digital Repository.

## Installation

### System Requirements

1. Install Docker
2. Install Ruby 2.6.4

### Check Out the Code

```bash
git clone https://github.com/sul-dlss/argo.git
cd argo
```

### Run bundler to install the Gem dependencies

```bash
bundle install
```

Note that `bundle install` may complain if MySQL isn't installed.  You can either comment out the `mysql2` inclusion in `Gemfile` and come back to it later (you can develop using `sqlite3`), or you can install MySQL.


## Run the tests locally

CI runs a series of steps;  this the sequence to do it locally, along with some helpful info.

1. **Pull down the latest docker containers**

    ```
    docker-compose pull
    ```

2. **Start up the docker services needed for testing**

    Once everything has been successfully pulled, start up the docker services needed for testing

    ```
    docker-compose up -d dor-services-app dor-indexing-app techmd
    ```

    You should do the following to make sure all the services are up:

    ```
    docker-compose ps
    ```

3. **Install Chrome**

    You will need to have Google Chrome browser installed, as the tests use chrome for a headless browser.

4. **Update javascript dependencies**

    ```
    yarn install
    ```

5. **Compile javascript**

    ```
    RAILS_ENV=test bin/rails webpacker:compile
    ```

    If you run into trouble with the docker containers complaining about webpacker, then ... figure out what to do to fix it and please update this document.  (There's a way to do it, something like `docker-compose run --container command`)

6. **Run the tests (without rubocop)**

    Note that

    ```
    RAILS_ENV=test bundle exec rake ci
    ```

    is a shortcut for running the following 2 steps:

    ```
    RAILS_ENV=test bundle exec rake argo:repo:load
    RAILS_ENV=test bundle exec rake spec
    ```

    `rake argo:repo:load` loads test fixture objects into fedora/solr.   You will NOT be able to re-run this task successfully unless fixtures are no longer in the docker containers (e.g. if you `docker-compose down`).  That is because they are already loaded.  The error messages in your terminal output do not surface this cause, but that is likely at play if you see `"Rubydora::FedoraInvalidRequest: See logger for details"`, esp with `"Caused by: RestClient::InternalServerError: 500 Internal Server Error"` in there. In this case, run only `bundle exec rake spec` instead.

    Note that `RAILS_ENV=test` should not be necessary when running `bundle exec rake spec` on its own.

7. **Problem test that fails locally but passes on CI**

    spec/helpers/items_helper_spec.rb:40

    ```
    ItemsHelper
      schema_validate
        validates a document (FAILED - 1)

    Failures:

      1) ItemsHelper schema_validate validates a document
         Failure/Error: expect(schema_validate(doc).length).to eq(3)

           expected: 3
                got: 2

           (compared using ==)
         # ./spec/helpers/items_helper_spec.rb:49:in `block (3 levels) in <top (required)>'

    Finished in 0.80643 seconds (files took 3.43 seconds to load)
    1 example, 1 failure
    ```

## Run the servers

```
docker-compose up -d
```

Note that docker-compose will spin up Argo and apply the administrator role to you.

If you want to use the rails console use:

```
docker-compose run --rm web bin/rails console
```

If you want to run background jobs, which are necessary for spreadsheet bulk uploads and indexing to run:

```
docker-compose run web bin/delayed_job start
```

Alternatively, you can also just immediately run any new jobs with interactive output visible
(and then quit the job worker).  This is useful for debugging and can also be used with "byebug"
to stop execution in the middle of an activejob for inspection:

```
docker-compose run web bin/rake jobs:workoff
```

Note, if you update the Gemfile or Gemfile.lock, you will need to rebuild the web docker container and reload the data:

```
docker-compose build web
docker-compose run --rm web bin/rake argo:repo:load
```

## Debugging

It can be useful when debugging to see the local rails server output in realtime and pause with 'byebug'.  You can do
this while running in the app in the web container.  First stop any existing web container (if running already):

```
docker-compose stop web
```

Then start it in a mode that is interactive:

```
docker-compose run --service-ports web
```

This will allow you to view rails output in real-time.  You can also add 'byebug' inline in your code to pause for inspection on the console.

### Note

If you run into errors related to the version of bundler when building the `web` container, that likely means you need to pull a newer copy of the base Ruby image specified in `Dockerfile`, e.g., `docker pull ruby:{MAJOR}.{MINOR}-stretch`.

Also, if you run into webpacker related issues, you may need to manually install yarn and compile webpacker in your Docker container (or local laptop if you running that way):

```
docker-compose run --rm web yarn install
docker-compose run --rm web bin/rake webpacker:compile
```

## Load and index records

```
docker-compose run --rm web bin/rake argo:repo:load
```


## Common tasks

### Run the tests

To run the test suite, invoke `rspec` from the Argo app root.  Note that the docker containers need to be running already for this work.
```bash
# docker-compose up -d # (if not already running)
rspec
```

### Run the continuous integration build

_Important Note: Running `rake ci` will reload fixtures for the `test` environment only._

The continuous integration build can be run by:

```bash
RAILS_ENV=test bundle exec rake ci
```

### Delete records

You cannot just load records twice and overwrite.  The repo namespace has been provisioned and you need to remove the old record first.

For example, using `rails console` to target one ID, or five:

```ruby
Dor.find("druid:pv820dk6668").destroy
%w[pv820dk6668 rn653dy9317 xb482bw3979 hj185vb7593 hv992ry2431].each{ |pid| Dor.find("druid:#{pid}").destroy }
```

## Internals

Argo uses Blacklight and ActiveFedora to expose the repository contents, and `dor-services` to enable editing and updating. Its key components include:

- Rails 5.2
- Blacklight 6
- dor-services
  - ActiveFedora
  - dor-workflow-service
- RSolr
- DelayedJob
- Bootstrap
- JQuery

and in development or testing mode:

- RSpec
- Capybara
- Chrome

## Background Job Workers (in deployed environments)

Argo uses the [eye](https://github.com/kostya/eye) gem to manage and monitor its DelayedJob-based background job workers in all deployed environments. To facilitate this, Argo defines Capistrano tasks in order to start, stop, and provide information about running workers:

```
$ cap {ENV} delayed_job:stop # stop workers in ENV environment
$ cap {ENV} delayed_job:start # start workers in ENV environment
$ cap {ENV} delayed_job:restart # restart workers in ENV environment
$ cap {ENV} delayed_job:status # view status of workers in ENV environment
```

The above tasks are linked into the [Capistrano flow](https://capistranorb.com/documentation/getting-started/flow/) so that workers are started and stopped at appropriate stages of deployments and rollbacks.

NOTE: If when invoking the `delayed_job:status` task, you see output like the following:

```
00:00 delayed_job:status
      01 ./bin/eye info delayed_job
      01 command :info, objects not found!
      01 command :info, objects not found!
    ✘ 01 lyberadmin@argo-qa-a.stanford.edu 0.801s
    ✘ 01 lyberadmin@argo-qa-b.stanford.edu 0.813s
```

This means the eye daemon was shutdown and did not restart. To start it back up, invoke `cap {ENV} delayed_job:reload`. Note that this is for reloading eye, not for restarting the workers. You should not have to invoke this task with any regularity; it is for recovering from unusual circumstances only.

## Further reading

### Indexing (including bulk reindexing)

For further reading on how indexing from Fedora to Solr works in Argo, see [INDEXING.md](INDEXING.md).  This explains how single object reindexing works, how the bulk reindexing mechanism works, and how to build custom reindexing runs.

### Profiling

For information on how to profile the app in the event of performance issues, see [PROFILING.md](PROFILING.md).  This explains how to collect profiling info, how to analyze it, how to approach the issue generally, and alternatives/complements to Argo's main built-in profiling tool.

[![CircleCI](https://circleci.com/gh/sul-dlss/argo.svg?style=svg)](https://circleci.com/gh/sul-dlss/argo)
[![Maintainability](https://api.codeclimate.com/v1/badges/fa27202b0a02e2d41486/maintainability)](https://codeclimate.com/github/sul-dlss/argo/maintainability)
[![Test Coverage](https://api.codeclimate.com/v1/badges/fa27202b0a02e2d41486/test_coverage)](https://codeclimate.com/github/sul-dlss/argo/test_coverage)
[![GitHub version](https://badge.fury.io/gh/sul-dlss%2Fargo.svg)](https://badge.fury.io/gh/sul-dlss%2Fargo)

# Argo

Argo is the administrative interface to the Stanford Digital Repository.

## Installation

### System Requirements

1. Install Docker
2. Install Ruby 3.0.3

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

    Once everything has been successfully pulled, start up the docker services needed for testing (all but the web container)

    ```
    docker-compose up -d sdr-api techmd
    ```

    You should do the following to make sure all the services are up:

    ```
    docker-compose ps
    ```

3. **Install Chrome**

    You will need to have Google Chrome browser installed, as the tests use chrome for a headless browser.

4. **Prepare rails for testing**

    ```
    bin/rails test:prepare
    ```

5. **Run rubocop and the tests**

    ```
    bin/rake
    ```

## Run the servers

```
docker compose up -d
```

Note that docker compose will spin up Argo and apply the administrator role to you.

If you want to use the rails console use:

```
docker compose run --rm web bin/rails console
```

If you want to run background jobs, which are necessary for spreadsheet bulk uploads and indexing to run:

```
docker compose run web sidekiq start
```

Note, if you update the Gemfile or Gemfile.lock, you will need to rebuild the web docker container.

```
docker compose build web
```

### Debugging

It can be useful when debugging to see the local rails server output in realtime and pause with 'byebug'.  You can do
this while running in the app in the web container.  First stop any existing web container (if running already):

```
docker compose stop web
```

Then start it in a mode that is interactive:

```
docker compose run --service-ports web
```

This will allow you to view rails output in real-time.  You can also add 'byebug' inline in your code to pause for inspection on the console.


### Note

If you run into errors related to the version of bundler when building the `web` container, that likely means you need to pull a newer copy of the base Ruby image specified in `Dockerfile`, e.g., `docker pull ruby:{MAJOR}.{MINOR}-stretch`.

You may also need to rebuild your web container without using Docker's cache (which may
have the older version of bundler in it).  This will ensure the web container
has the latest version of the bundler gem installed.  You may then also need to update the
bundler version in the Gemfile.lock to match.

```
gem update --system && gem install bundler # get the latest version of bundler locally
bundle update --bundler  # update the Gemfile.lock to match this while not updating any gems
docker-compose build --no-cache web # rebuild the docker container to match the latest bundler
```

Also, if you run into asset related issues, you may need to manually install yarn and compile assets in your Docker container (or local laptop if you running that way):

```
docker compose run --rm web yarn install
docker compose run --rm web bin/rails assets:precompile
```

## Running locally

First install foreman (foreman is not supposed to be in the Gemfile, See this [wiki article](https://github.com/ddollar/foreman/wiki/Don't-Bundle-Foreman) ):

```
gem install foreman
```

Then you can run
```
bin/dev
```
This starts css/js bundling and the development server

## Creating fixture data

To begin registering items in the Argo UI, there will need to be at least one agreement object and one APO object in the index. To create and index one of each of these objects, run the following command:

```
docker compose exec web bin/rails db:seed
```

## Internals

Argo uses Blacklight and ActiveFedora to expose the repository contents, and `dor-services` to enable editing and updating. Its key components include:

- Rails 5.2
- Blacklight 7
- dor-services-client
- RSolr
- Sidekiq
- Bootstrap
- JQuery

and in development or testing mode:

- RSpec
- Capybara
- Chrome

## Background Job Workers (in deployed environments)

Argo uses systemd to manage and monitor its Sidekiq-based background job workers in all deployed environments. See  [Sidekiq via systemd](https://github.com/sul-dlss/dlss-capistrano#sidekiq-via-systemd)

## Further reading

### Indexing (including bulk reindexing)

For further reading on how indexing from Fedora to Solr works in Argo, see [INDEXING.md](INDEXING.md).  This explains how single object reindexing works, how the bulk reindexing mechanism works, and how to build custom reindexing runs.

### Profiling

For information on how to profile the app in the event of performance issues, see [PROFILING.md](PROFILING.md).  This explains how to collect profiling info, how to analyze it, how to approach the issue generally, and alternatives/complements to Argo's main built-in profiling tool.

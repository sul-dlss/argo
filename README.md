[![CircleCI](https://circleci.com/gh/sul-dlss/argo.svg?style=svg)](https://circleci.com/gh/sul-dlss/argo)
[![Maintainability](https://api.codeclimate.com/v1/badges/fa27202b0a02e2d41486/maintainability)](https://codeclimate.com/github/sul-dlss/argo/maintainability)
[![Test Coverage](https://api.codeclimate.com/v1/badges/fa27202b0a02e2d41486/test_coverage)](https://codeclimate.com/github/sul-dlss/argo/test_coverage)
[![GitHub version](https://badge.fury.io/gh/sul-dlss%2Fargo.svg)](https://badge.fury.io/gh/sul-dlss%2Fargo)

# Argo

Argo is the administrative interface to the Stanford Digital Repository.

## Installation

### System Requirements

1. Install Docker
2. Install Ruby 3.2.2

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

Install foreman for local development (foreman is not supposed to be in the Gemfile, See this [wiki article](https://github.com/ddollar/foreman/wiki/Don't-Bundle-Foreman)):

```bash
gem install foreman
```

## Local Development TL;DR

Brings up app at localhost:3000 with some test data:

```
gem install foreman
docker compose up -d
docker compose stop web
REMOTE_DEBUGGER=byebug bin/dev # omit REMOTE_DEBUGGER if you don't need a debugger
bin/rake argo:seed_data # run in separate terminal window
bundle exec byebug -R localhost:8989 # run in separate terminal window
```

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

5. **Run the linters and the tests**

    ```
    bin/rake
    ```

To run just the linters, run `bin/rake lint`. To run the linters individually, run `bundle exec erblint --lint-all`, `bundle exec rubocop`, and `yarn run lint`

## Docker

This will spin up all of the docker containers in the background.  Note that docker compose will spin up an Argo web container and apply the administrator role to you.  You will need to stop this web container if you use a local rails server instead.  See the "Recommended Local Development" section below.

```
docker compose up -d
```

If you want to run the web container in interactive mode, stop it first and then run it so it will show interactive live output:

```
docker compose stop web
docker compose run --service-ports web
```

If you want to use the rails console from the web container use:

```
docker compose run --rm web bin/rails console
```

If you want to run background jobs, which are necessary for spreadsheet bulk uploads and indexing to run:

```
docker compose run web sidekiq start
```

## Recommended Local Development

Be sure all of the docker containers for dependent services are running in the background (e.g. solr, DSA) and stop the web container:

```
docker compose up -d
docker compose stop web
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

To enable interactive debugging, invoke `bin/dev` as follows:

```
REMOTE_DEBUGGER=byebug bin/dev
```

And then start up the debugger in another window (only byebug is supported at this time):

```
bundle exec byebug -R localhost:8989
```

Note that, by default, the debugger will run on `localhost` on port `8989`. To change these values, add the `DEBUGGER_HOST` and `DEBUGGER_PORT` environment variables when invoking `bin/dev` above and make sure to poing `byebug -R` at those same values when starting up the debugger.

## Local Development Troubleshooting

If you get an error starting the local server (e.g. with `bin/dev`) first be sure you have all the dependent docker containers running, and the web container stopped.

If you update the Gemfile and you are using the `web` container, you will need to rebuild it:

```
docker compose build web
```

If you run into errors related to the version of bundler when building the `web` container, that likely means you need to pull a newer copy of the base Ruby image specified in `Dockerfile`, e.g., `docker pull ruby:{MAJOR}.{MINOR}-stretch`.

You may also need to rebuild your web container without using Docker's cache (which may have the older version of bundler in it).  This will ensure the web container has the latest version of the bundler gem installed.  You may then also need to update the bundler version in the Gemfile.lock to match.

```
gem update --system && gem install bundler # get the latest version of bundler locally
bundle update --bundler  # update the Gemfile.lock to match this while not updating any gems
docker-compose build --no-cache web # rebuild the docker container to match the latest bundler
```

If you run into asset related issues, you may need to manually install yarn and compile assets in your Docker container (or local laptop by leaving off the `docker compose run --rm`):

```
docker compose run --rm web yarn install
docker compose run --rm web bin/rails assets:precompile
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

Argo uses Blacklight and ActiveFedora to expose the repository contents, and `dor-services` to enable editing and updating. Its key components include:

- Rails 5.2
- Blacklight 7
- dor-services-client
- RSolr
- Sidekiq
- Bootstrap

and in development or testing mode:

- RSpec
- Capybara
- Chrome

## Background Job Workers (in deployed environments)

Argo uses systemd to manage and monitor its Sidekiq-based background job workers in all deployed environments. See  [Sidekiq via systemd](https://github.com/sul-dlss/dlss-capistrano#sidekiq-via-systemd)

## Reset Process (for QA/Stage)

### Steps

1. [Reset the database](https://github.com/sul-dlss/DeveloperPlaybook/blob/main/best-practices/db_reset.md)
2. Clear the bulk directory: `rm -fr /workspace/bulk/*`

## Further reading

### Indexing (including bulk reindexing)

For further reading on how indexing from Fedora to Solr works in Argo, see [INDEXING.md](INDEXING.md).  This explains how single object reindexing works, how the bulk reindexing mechanism works, and how to build custom reindexing runs.

### Profiling

For information on how to profile the app in the event of performance issues, see [PROFILING.md](PROFILING.md).  This explains how to collect profiling info, how to analyze it, how to approach the issue generally, and alternatives/complements to Argo's main built-in profiling tool.

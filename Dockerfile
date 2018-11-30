FROM ruby:2.5-stretch

RUN apt-get update -qq && \
    apt-get install -y nano build-essential libsqlite3-dev nodejs

WORKDIR /app
ADD Gemfile Gemfile.lock /app/
RUN bundle install

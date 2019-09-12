FROM ruby:2.5-stretch

RUN apt-get update -qq && \
    apt-get install -y nano build-essential libsqlite3-dev nodejs

WORKDIR /app
ADD Gemfile Gemfile.lock /app/

# Get bundler 2.0 for ruby 2.6.4
RUN gem install bundler

RUN bundle install

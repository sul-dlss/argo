FROM ruby:2.6-stretch

RUN apt-get update \
    && apt-get install -y apt-transport-https \
    && curl --silent --show-error --location \
      https://deb.nodesource.com/gpgkey/nodesource.gpg.key | apt-key add - \
    && echo "deb https://deb.nodesource.com/node_12.x/ stretch main" > /etc/apt/sources.list.d/nodesource.list \
    && curl --silent --show-error --location https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - \
    && echo "deb https://dl.yarnpkg.com/debian/ stable main" > /etc/apt/sources.list.d/yarn.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
    nodejs apt-transport-https yarn \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Get bundler 2.0 for ruby 2.6.4
RUN gem install bundler


WORKDIR /app

ADD Gemfile Gemfile.lock /app/

RUN bundle install

COPY package.json yarn.lock ./
RUN yarn install

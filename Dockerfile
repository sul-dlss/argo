FROM ruby:2.6.4-alpine

RUN apk add --update --no-cache \
  build-base \
  # speed up nokogiri gem installation
  libxml2-dev \
  libxslt-dev \
  # needed for mysql2 dependency
  mariadb-dev \
  # needed for eye dependency
  perl \
  # needed for sqlite dependency
  sqlite-dev \
  # rails server cannot start without tzdata
  tzdata \
  yarn

WORKDIR /app

RUN gem update --system && \
  gem install bundler

COPY Gemfile Gemfile.lock ./
RUN bundle config build.nokogiri --use-system-libraries && \
  bundle config set without 'production' && \
  bundle install

COPY package.json yarn.lock ./
RUN yarn install

COPY . .

CMD ["bin/puma", "-C", "config/puma.rb", "config.ru"]

FROM ruby:3.4.1-bookworm

RUN curl -fsSL https://deb.nodesource.com/setup_current.x | bash -

RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
    && apt-get -y install --no-install-recommends \
        mariadb-client libmariadb-dev \
        libxml2-dev \
        sqlite3 \
        # clang is required for openapi_parser and commonmarker
        clang \
        nodejs

WORKDIR /app

RUN npm install -g yarn

RUN gem update --system && \
  gem install bundler

COPY Gemfile Gemfile.lock ./
RUN bundle config build.nokogiri --use-system-libraries && \
  bundle config set without 'production' && \
  bundle install

RUN gem install foreman

COPY package.json yarn.lock ./
RUN yarn install

COPY . .

CMD ["docker/entrypoint.sh"]

FROM ruby:3.3-alpine
LABEL maintainer="Justin Collins <gem@brakeman.org>"

WORKDIR /usr/src/app

RUN apk --update add build-base

# Copy our Gemfile (and related files) *without* copying our actual source code yet
COPY Gemfile* *.gemspec gem_common.rb ./
# Copy lib/brakeman/version.rb so that bundle install works
COPY lib/brakeman/version.rb ./lib/brakeman/

# Install the necessary gems
RUN bundle install --jobs 4 --without "development test"

# Copy in the latest Brakeman source code as the final stage
COPY . /usr/src/app

# Default to looking for source in /code
WORKDIR /code

ENTRYPOINT ["/usr/src/app/bin/brakeman"]

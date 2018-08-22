FROM ruby:2.4-alpine
LABEL maintainer="Justin Collins"

WORKDIR /usr/src/app

# Create user named app with uid=9000, give it ownership of /usr/src/app (TODO: document what '-D app' does)
RUN adduser -u 9000 -D app && \
    chown -R app:app /usr/src/app
USER app

# Install the necessary gems
RUN bundle install --jobs 4 --without "development test"

# Copy in the latest Brakeman source code at the final stage
COPY . /usr/src/app

VOLUME /code
WORKDIR /code

ENTRYPOINT ["/usr/src/app/bin/brakeman"]

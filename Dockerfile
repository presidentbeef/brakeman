FROM ruby:2.4-alpine
LABEL maintainer="Justin Collins"

WORKDIR /usr/src/app
COPY . /usr/src/app
RUN adduser -u 9000 -D app && \
    chown -R app:app /usr/src/app
USER app

RUN bundle install --jobs 4 --without "development test"

VOLUME /code
WORKDIR /code

ENTRYPOINT ["/usr/src/app/bin/brakeman"]

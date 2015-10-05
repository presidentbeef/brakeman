FROM ruby:2.2.3-slim
MAINTAINER Justin Collins

WORKDIR /usr/src/app
COPY Gemfile* /usr/src/app/
COPY brakeman.gemspec /usr/src/app/
COPY lib/brakeman/version.rb /usr/src/app/lib/brakeman/

RUN apt-get update && \
    apt-get install -y git && \
    bundle install --jobs 4 --without "development test" && \
    adduser --uid 9000 app

COPY . /usr/src/app
RUN chown -R app:app /usr/src/app
USER app

VOLUME /code
WORKDIR /code

CMD ["/usr/src/app/bin/codeclimate-brakeman"]

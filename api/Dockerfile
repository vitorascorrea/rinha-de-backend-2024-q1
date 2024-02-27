FROM ruby:latest as base
ENV RAILS_ENV="production" \
  RUBY_YJIT_ENABLE="1"

RUN apt-get update -qq && apt-get install -y build-essential apt-utils libpq-dev nodejs
WORKDIR /docker/app
RUN gem install bundler
COPY Gemfile* ./
RUN bundle install
ADD . /docker/app
ARG DEFAULT_PORT 5000
EXPOSE ${DEFAULT_PORT}
CMD ["rails","server", "-b", "0.0.0.0", "-p", "5000"]

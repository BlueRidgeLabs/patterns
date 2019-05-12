FROM ruby:2.6.2
RUN apt-get update -qq && apt-get install -y build-essential libsodium-dev libpq-dev nodejs && apt-get autoremove -y && apt-get clean
RUN mkdir /app
WORKDIR /app
COPY Gemfile /app/Gemfile
COPY Gemfile.lock /app/Gemfile.lock
RUN bundle install
COPY . /app

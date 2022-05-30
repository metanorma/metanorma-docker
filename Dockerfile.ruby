FROM ruby:3.1.1-slim-bullseye
USER root

LABEL maintainer="open.source@ribose.com"

ARG METANORMA_IMAGE_NAME=metanorma

ENV DEBIAN_FRONTEND=noninteractive

RUN mkdir -p /setup

# https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=863199#23
RUN mkdir -p /usr/share/man/man1

COPY ./ubuntu.sh /setup/ubuntu.sh

# install dependencies
RUN apt-get update && \
  apt-get install -y curl gnupg2 software-properties-common python3-pip snapd && \
  bash -c /setup/ubuntu.sh && \
  apt-get clean && rm -rf /var/lib/apt/lists/*

# install latest bundler
RUN gem install bundler

# install metanorma toolchain
COPY $METANORMA_IMAGE_NAME/Gemfile /setup/Gemfile
# --redownload need to fix rake Bundler::GemNotFound
# --no-cache https://github.com/rubygems/rubygems/issues/3225
RUN --mount=type=secret,id=bundle_config,dst=/usr/local/bundle/config \
    --mount=type=secret,id=gemrc_config,dst=$GEM_HOME/.gemrc \
  cd /setup && \
  bundle config set without development test \
  bundle install --no-cache --redownload && \
  rm -rf /usr/local/bundle/cache

# export java executable path
ENV JAVA_HOME /usr/lib/jvm/default-java
ENV PATH $PATH:$JAVA_HOME/bin
ENV RUBYOPT -rbundler/setup
ENV BUNDLE_GEMFILE /setup/Gemfile

# Workaround for rubygems/bundler#7494
# TODO: Supposed to be already fixed but why is this necessary?
ENV GEM_PATH $GEM_HOME:$GEM_HOME/ruby/$RUBY_MAJOR.0
ENV PATH $GEM_HOME/bin:$GEM_HOME/ruby/$RUBY_MAJOR.0/bin:$PATH

# Workaround for https://github.com/relaton/relaton/issues/99
ENV RELATON_FETCH_PARALLEL 1

ENV FONTIST_PATH "/config"
VOLUME /config/fonts

WORKDIR /metanorma
CMD metanorma

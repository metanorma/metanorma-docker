FROM ruby:3.1.1-slim-bullseye
USER root

LABEL maintainer="open.source@ribose.com"

ARG METANORMA_IMAGE_NAME=metanorma

ENV DEBIAN_FRONTEND=noninteractive

# install dependencies
RUN apt-get update && \
  apt-get install -y curl gnupg2 software-properties-common python3-pip snapd && \
  apt-get clean && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /setup

# https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=863199#23
RUN mkdir -p /usr/share/man/man1

COPY ./ubuntu.sh /setup/ubuntu.sh
RUN apt-get update && bash -c /setup/ubuntu.sh && \
  apt-get clean && rm -rf /var/lib/apt/lists/* && \
  rm -rf /root/.cpan/build

# install latest bundler
RUN gem install bundler

# install metanorma toolchain
COPY $METANORMA_IMAGE_NAME/Gemfile /setup/Gemfile
# --redownload need to fix rake Bundler::GemNotFound
# --no-cache https://github.com/rubygems/rubygems/issues/3225
RUN --mount=type=secret,id=bundle_config,dst=/usr/local/bundle/config \
  cd /setup && \
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

ENV FONTIST_PATH "/config"
VOLUME /config/fonts

WORKDIR /metanorma
CMD metanorma

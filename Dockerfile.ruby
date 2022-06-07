FROM ruby:3.1.1-slim-bullseye
USER root

LABEL maintainer="open.source@ribose.com"

ARG METANORMA_IMAGE_NAME=metanorma

ENV DEBIAN_FRONTEND=noninteractive

# https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=863199#23
RUN mkdir -p /usr/share/man/man1

# install dependencies
RUN apt-get update && \
    apt-get --no-install-recommends install -y curl git make sassc && \
    apt-get update && curl -L "https://raw.githubusercontent.com/metanorma/plantuml-install/main/ubuntu.sh" | bash && \
    apt-get --no-install-recommends install -y software-properties-common gnupg2 && \
    apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 9DA4BD18B9A06DE3 && \
    add-apt-repository ppa:inkscape.dev/stable && \
    apt-get --no-install-recommends install -y inkscape && \
    rm -rf /usr/share/inkscape/tutorials && \
    apt-get --no-install-recommends install -y python3-pip python3-setuptools python3-wheel && \
    pip3 install --no-cache-dir idnits xml2rfc --ignore-installed six chardet && rm -rf /root/.cache/pip && \
    apt-get purge -y python3-pip python3-setuptools python3-wheel && \
    apt-get autoremove -y && apt-get clean && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# install metanorma toolchain
RUN mkdir -p /setup
COPY $METANORMA_IMAGE_NAME/Gemfile /setup/Gemfile
RUN --mount=type=secret,id=bundle_config,dst=/usr/local/bundle/config \
    --mount=type=secret,id=gemrc_config,dst=$GEM_HOME/.gemrc \
  gem install bundler && \
  apt-get update && apt-get --no-install-recommends install -y gcc g++ cmake libxml2-dev libxslt-dev libsass-dev && \
  cd /setup && \
  bundle config --local set without development test && \
  bundle install --no-cache --redownload && \
  rm -rf /usr/local/bundle/cache && \
  find /usr/local/bundle/gems -type d -name 'spec' -prune -exec rm -r "{}" \; && \
  find /usr/local/bundle/gems -type d -name 'test' -prune -exec rm -r "{}" \; && \
  apt-get purge -y gcc g++ ruby-dev cmake libxml2-dev libxslt-dev libsass-dev && \
  apt-get autoremove -y && apt-get clean && rm -rf /var/lib/apt/lists/*

RUN fontist update

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

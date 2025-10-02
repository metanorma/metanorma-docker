FROM ruby:3.3.7-slim-bookworm
USER root

LABEL maintainer="open.source@ribose.com" \
      org.opencontainers.image.authors="open.source@ribose.com" \
      org.opencontainers.image.url="https://www.metanorma.org" \
      org.opencontainers.image.documentation="https://www.metanorma.org" \
      org.opencontainers.image.title="Metanorma" \
      org.opencontainers.image.description="Metanorma document processing toolchain (Ruby variant)"

ARG METANORMA_IMAGE_NAME=metanorma

ENV DEBIAN_FRONTEND=noninteractive

# https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=863199#23
RUN mkdir -p /usr/share/man/man1

# Install runtime dependencies
RUN apt-get update && \
    apt-get --no-install-recommends install -y \
        curl \
        git \
        make \
        gnupg2 \
        inkscape \
        software-properties-common \
        python3 \
        python3-lxml \
        openjdk-17-jdk \
        graphviz \
        && rm -rf /usr/share/inkscape/tutorials \
        && apt-get clean \
        && rm -rf /var/lib/apt/lists/*

# Install XML2RFC using a separate layer to minimize image size
RUN apt-get update && \
    apt-get --no-install-recommends install -y \
        python3-pip \
        python3-wheel \
        python3-setuptools \
        && pip3 install --break-system-packages --no-cache-dir \
        --upgrade pip wheel xml2rfc \
        --ignore-installed six chardet \
        && rm -rf /root/.cache/pip \
        && apt-get purge -y python3-pip python3-setuptools python3-wheel \
        && apt-get autoremove -y \
        && apt-get clean \
        && rm -rf /var/lib/apt/lists/*

# Set up directories
RUN mkdir -p /setup

# Copy Gemfile
COPY $METANORMA_IMAGE_NAME/Gemfile /setup/Gemfile

# Set bundle environment
ENV BUNDLE_WITHOUT="development:test"

# Install metanorma toolchain
RUN --mount=type=secret,id=bundle_config,dst=/usr/local/bundle/config \
    --mount=type=secret,id=gemrc_config,dst=$GEM_HOME/.gemrc \
    gem install bundler -v "~> 2.6.5" && \
    apt-get update && \
    apt-get --no-install-recommends install -y \
        gcc \
        g++ \
        cmake \
        libxml2-dev \
        libxslt-dev \
        libyaml-dev \
        zlib1g-dev && \
    cd /setup && \
    bundle install --no-cache --redownload && \
    rm -rf /usr/local/bundle/cache && \
    find /usr/local/bundle/gems -type d -name 'spec' -prune -exec rm -r "{}" \; && \
    find /usr/local/bundle/gems -type d -name 'test' -prune -exec rm -r "{}" \; && \
    apt-get purge -y gcc g++ cmake libxml2-dev libxslt-dev libyaml-dev zlib1g-dev && \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Update fontist
RUN fontist update

# Set environment variables
# Remember to change the version number if you change the Ruby version
ENV JAVA_HOME=/usr/lib/jvm/default-java \
    PATH=$PATH:/usr/lib/jvm/default-java/bin \
    RUBYOPT=-rbundler/setup \
    BUNDLE_GEMFILE=/setup/Gemfile \
    RELATON_FETCH_PARALLEL=1 \
    FONTIST_PATH="/config" \
    GEM_PATH=$GEM_HOME:$GEM_HOME/ruby/3.3.0 \
    PATH=$GEM_HOME/bin:$GEM_HOME/ruby/3.3.0/bin:$PATH

# Set up volume for fonts
VOLUME /config/fonts

# Set working directory
WORKDIR /metanorma

# Set default command
CMD ["metanorma"]

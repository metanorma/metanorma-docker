#!/bin/bash -e

# Set up prerequisites
apt-get install -y curl git make gcc ruby-bundler ruby-dev cmake \
  libxml2-dev libxslt-dev \
  libsass-dev sassc

curl -L "https://raw.githubusercontent.com/metanorma/plantuml-install/main/ubuntu.sh" | bash

# Install xml2rfc
apt-get -y install python3-pip python3-setuptools python3-wheel
pip3 install idnits xml2rfc --ignore-installed six chardet

# Install inkscape
add-apt-repository ppa:inkscape.dev/stable
apt-get install -y inkscape
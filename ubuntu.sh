#!/bin/bash -e

# Set up prerequisites
apt-get install -y curl git make gcc ruby-bundler ruby-dev \
  libxml2-dev libxslt-dev \
  libsass-dev sassc

curl -L "https://raw.githubusercontent.com/metanorma/plantuml-install/master/ubuntu.sh" | bash

# Install latexml
command -v cpanm >/dev/null 2>&1 || {
  curl -L http://cpanmin.us | perl - App::cpanminus
}
cpanm --notest XML::LibXSLT@1.96 git://github.com/brucemiller/LaTeXML.git@9a0e7dc5

# Install idnits & xml2rfc
apt-get -y install python3-pip python3-setuptools python3-wheel
# pip3 install --upgrade pip
pip3 install idnits xml2rfc --ignore-installed six chardet

export IDNITS_URL=https://tools.ietf.org/tools/idnits/
export IDNITS_VER=$(curl -Ls $IDNITS_URL | grep -e 'tgz' | sed -e 's/.*\(idnits-.*\).tgz.*/\1/') ; echo ${IDNITS_VER}
curl -SL ${IDNITS_URL}${IDNITS_VER} | tar xzv
export PATH=$(pwd)/${IDNITS_VER}:${PATH}

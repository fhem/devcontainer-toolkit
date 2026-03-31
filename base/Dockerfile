FROM ghcr.io/fhem/fhem-minimal-docker:5-bookworm

ARG LOCAL_UID=1000
ARG LOCAL_GID=1000
ARG LOCAL_USER=dev

COPY base/cpanfile /usr/src/app/core/cpanfile

RUN apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    ca-certificates \
    git \
    less \
    openssh-client \
    procps \
    subversion \
 && rm -rf /var/lib/apt/lists/*

RUN groupadd --gid ${LOCAL_GID} ${LOCAL_USER} \
 && useradd --uid ${LOCAL_UID} --gid ${LOCAL_GID} --create-home --shell /bin/bash ${LOCAL_USER}

ENV HOME=/home/${LOCAL_USER}

RUN cpm install --cpanfile /usr/src/app/core/cpanfile \
    --show-build-log-on-failure \
    --with-recommends \
    --without-test \
    --workers=$(nproc) \
    -L /usr/src/app/core

ENV PERL5LIB=/usr/src/app/core/lib/perl5

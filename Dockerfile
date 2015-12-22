FROM buildpack-deps:jessie
MAINTAINER Josh W Lewis <josh.w.lewis@gmail.com>

# Install additional apt packages and setup locale
RUN apt-get update \
    && apt-get install -y --no-install-recommends locales inotify-tools \
    && export LANG=en_US.UTF-8 \
    && echo $LANG UTF-8 > /etc/locale.gen \
    && locale-gen \
    && update-locale LANG=$LANG \
    && rm -rf /var/lib/apt/lists/*

ENV LANG=en_US.UTF-8 \
    LANGUAGE=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8

# Install Erlang/OTP
ENV OTP_VERSION=18.1.3
RUN set -xe \
    && curl -sSL -o otp.tar.gz \
    "https://codeload.github.com/erlang/otp/tar.gz/OTP-${OTP_VERSION}" \
    && mkdir -p /usr/src/otp \
    && tar -xzC /usr/src/otp --strip-components=1 -f otp.tar.gz \
    && rm otp.tar.gz \
    && cd /usr/src/otp \
    && ./otp_build autoconf \
    && ./configure \
    && make -j$(nproc) \
    && make install \
    && rm -rf /usr/src/otp

# Install Elixir
ENV ELIXIR_VERSION=1.1.1
RUN set -xe \
    && curl -sSL -o elixir.tar.gz \
    "https://codeload.github.com/elixir-lang/elixir/tar.gz/v${ELIXIR_VERSION}" \
    && mkdir -p /usr/src/elixir \
    && tar -xzC /usr/src/elixir --strip-components=1 -f elixir.tar.gz \
    && rm elixir.tar.gz \
    && cd /usr/src/elixir \
    && make -j$(nproc) clean install \
    && rm -rf /usr/src/elixir

# Install nodejs (and npm)
ENV NODE_VERSION 4.2.3
RUN set -xe \
    && curl -sSL -o nodejs.tar.gz \
    "https://codeload.github.com/nodejs/node/tar.gz/v${NODE_VERSION}" \
    && mkdir -p /usr/src/nodejs \
    && tar -xzC /usr/src/nodejs --strip-components=1 -f nodejs.tar.gz \
    && rm nodejs.tar.gz \
    && cd /usr/src/nodejs \
    && ./configure \
    && make -j$(nproc) \
    && make install \
    && rm -rf /usr/src/nodejs

# Install hex, rebar, and Phoenix mix archives
ENV PHOENIX_VERSION=1.1.0 \
    HOME=/app
RUN mix local.hex --force \
    && mix local.rebar --force \
    && mix archive.install --force \
    "https://github.com/phoenixframework/phoenix/releases/download/v${PHOENIX_VERSION}/phoenix_new-${PHOENIX_VERSION}.ez"
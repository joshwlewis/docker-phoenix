FROM alpine:3.3
MAINTAINER Josh W Lewis <josh.w.lewis@gmail.com>

ENV OTP_VERSION=18.2.1 \
    ELIXIR_VERSION=1.2.0 \
    NODE_VERSION=4.2.4 \
    PHOENIX_VERSION=1.1.1 \
    MIX_HOME=/usr/share/mix \
    HEX_HOME=/usr/share/hex

# Install build dependencies
RUN apk --update add --no-cache curl openssl git make gcc libc-dev libgcc
RUN apk --update add --no-cache --virtual compile-deps linux-headers tar \
    g++ autoconf openssl-dev ncurses-dev python binutils-gold paxctl

# Install Erlang/OTP
RUN set -xe \
    && curl -sSL -o otp.tar.gz \
    "https://codeload.github.com/erlang/otp/tar.gz/OTP-${OTP_VERSION}" \
    && mkdir -p /usr/src/otp \
    && tar -xzC /usr/src/otp --strip-components=1 -f otp.tar.gz \
    && rm otp.tar.gz \
    && cd /usr/src/otp \
    && ./otp_build autoconf \
    && ./configure \
    && make -j$(grep -c ^processor /proc/cpuinfo 2>/dev/null || 1) \
    && make install \
    && rm -rf /usr/src/otp

# Install Elixir
RUN set -xe \
    && curl -sSL -o elixir.tar.gz \
    "https://codeload.github.com/elixir-lang/elixir/tar.gz/v${ELIXIR_VERSION}" \
    && mkdir -p /usr/src/elixir \
    && tar -xzC /usr/src/elixir --strip-components=1 -f elixir.tar.gz \
    && rm elixir.tar.gz \
    && cd /usr/src/elixir \
    && make clean install \
    && rm -rf /usr/src/elixir

# Install nodejs (and npm)
RUN set -xe \
    && curl -sSL -o nodejs.tar.gz \
    "https://codeload.github.com/nodejs/node/tar.gz/v${NODE_VERSION}" \
    && mkdir -p /usr/src/nodejs \
    && tar -xzC /usr/src/nodejs --strip-components=1 -f nodejs.tar.gz \
    && rm nodejs.tar.gz \
    && cd /usr/src/nodejs \
    && ./configure --prefix=/usr --without-snapshot \
    && make -j$(grep -c ^processor /proc/cpuinfo 2>/dev/null || 1) \
    && make install \
    && paxctl -cm /usr/bin/node \
    && rm -rf /usr/src/nodejs

# Install hex, rebar, and Phoenix mix archives
RUN mix local.hex --force \
    && mix local.rebar --force \
    && mix archive.install --force \
    "https://github.com/phoenixframework/archives/raw/master/phoenix_new-${PHOENIX_VERSION}.ez"

RUN apk del compile-deps
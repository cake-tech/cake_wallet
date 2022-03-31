FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y curl clang unzip automake build-essential file pkg-config \
                       git python libtool libtinfo5 cmake openjdk-8-jre-headless && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /opt/android/cake_wallet/scripts/android

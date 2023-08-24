FROM ubuntu:20.04
LABEL authors="konsti"

ENV MONERO_BRANCH=release-v0.18.2.2-android
RUN apt-get update && \
    echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections && \
    apt-get install -y dialog apt-utils curl unzip automake build-essential file pkg-config git python libtool libtinfo5 cmake clang

RUN mkdir /opt/android/

COPY . /opt/android/cakewallet/

WORKDIR /opt/android/cakewallet/


RUN ./install_ndk.sh

RUN ./build_iconv.sh
RUN ./build_boost.sh
RUN ./build_openssl.sh
RUN ./build_sodium.sh
RUN ./build_unbound.sh
RUN ./build_zmq.sh


ENTRYPOINT ["./entrypoint.sh"]

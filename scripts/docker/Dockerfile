FROM ubuntu:20.04
LABEL authors="konsti"

ENV MONERO_BRANCH=release-v0.18.2.2-android
RUN apt-get update && \
    echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections && \
    apt-get install -y dialog apt-utils curl unzip automake build-essential file pkg-config git python libtool libtinfo5 cmake clang bison ccache

RUN mkdir /opt/android/

WORKDIR /opt/android/cakewallet/

# build_all.sh
# build_boost.sh
# build_iconv.sh
# build_monero.sh
# build_openssl.sh
# build_sodium.sh
# build_unbound.sh
# build_zmq.sh
# config.sh
# copy_haven_deps.sh
# copy_monero_deps.sh
# docker-compose.yml
# entrypoint.sh
# finish_boost.sh
# init_boost.sh
# install_ndk.sh

COPY config.sh /opt/android/cakewallet/
COPY install_ndk.sh /opt/android/cakewallet/
RUN ./install_ndk.sh

COPY build_iconv.sh /opt/android/cakewallet/
RUN ./build_iconv.sh

COPY build_boost.sh /opt/android/cakewallet/
COPY init_boost.sh /opt/android/cakewallet/
COPY finish_boost.sh /opt/android/cakewallet/
RUN ./build_boost.sh

COPY build_openssl.sh /opt/android/cakewallet/
RUN ./build_openssl.sh

COPY build_sodium.sh /opt/android/cakewallet/
RUN ./build_sodium.sh

COPY build_unbound.sh /opt/android/cakewallet/
RUN ./build_unbound.sh

COPY build_zmq.sh /opt/android/cakewallet/
RUN ./build_zmq.sh

COPY entrypoint.sh /opt/android/cakewallet/
COPY build_monero.sh /opt/android/cakewallet/
COPY copy_monero_deps.sh /opt/android/cakewallet/

ENTRYPOINT ["./entrypoint.sh"]

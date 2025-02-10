# Building Cake Wallet for Android

## Requirements and Setup

As we use Docker with a custom Dockerfile to build Cake Wallet, the only dependency for building Cake on your local host is the Docker Engine.

You can find the latest instructions for installing Docker on your given OS on the official website:

- <https://docs.docker.com/engine/install/>

## Building Cake Wallet or Monero.com

In order to build the latest version of Cake Wallet, simply run the following:

```bash
git clone https://github.com/cake-tech/cake_wallet.git
cd cake_wallet
docker build -t cakewallet:latest .
```

To build Monero.com Wallet instead, run:

```bash
git clone https://github.com/cake-tech/cake_wallet.git
cd cake_wallet
docker build --build-arg APP_NAME=monero.com -t cakewallet:latest .
```

## Validating output

To get the SHA-256 hashes of the built APKs, simply run:

```bash
docker run --rm -it cakewallet:latest
```

You should get output similar to:

```bash
WIP
```

Compare the hash of the build that you generated to the developer hash of the same release on Github, i.e. `v4.23.0`.

## Signing builds

While signing builds is outside of the scope of this guide (very few users want or need to run their own built APKs), to learn more about how to sign APKs you can check out the Zeus team's fantastic guide:

- <https://github.com/ZeusLN/zeus/blob/master/docs/ReproducibleBuilds.md#signing-apks>

package com.cakewallet.cw_keychain

import kotlinx.serialization.Serializable

@Serializable
internal data class KeychainDataWrapper(
  val name: String,
  val walletTypeRaw: Long,
  val seed: String,
  val networkRaw: Long,
  val version: Long,
  val derivationTypeRaw: Long,
  val derivationPath: String? = null,
  val seedTypeRaw: Long? = null,
  val blockHeight: Long? = null,
  val passphrase: String? = null,
) {

  constructor(pigeonData: KeychainData) : this(
    name = pigeonData.name,
    walletTypeRaw = pigeonData.walletTypeRaw,
    seed = pigeonData.seed,
    networkRaw = pigeonData.networkRaw,
    version = pigeonData.version,
    derivationTypeRaw = pigeonData.derivationTypeRaw,
    derivationPath = pigeonData.derivationPath,
    seedTypeRaw = pigeonData.seedTypeRaw,
    blockHeight = pigeonData.blockHeight,
    passphrase = pigeonData.passphrase,
  )

  val accountId: String
    get() = "${name}_$walletTypeRaw"

  fun toPigeonData(): KeychainData = KeychainData(
    version = version,
    name = name,
    walletTypeRaw = walletTypeRaw,
    seed = seed,
    networkRaw = networkRaw,
    derivationTypeRaw = derivationTypeRaw,
    derivationPath = derivationPath,
    seedTypeRaw = seedTypeRaw,
    blockHeight = blockHeight,
    passphrase = passphrase,
  )
}

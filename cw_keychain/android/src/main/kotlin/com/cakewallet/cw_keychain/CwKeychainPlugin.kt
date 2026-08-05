package com.cakewallet.cw_keychain

import io.flutter.embedding.engine.plugins.FlutterPlugin

/** Android host implementation of the cw_keychain platform apis. */
class CwKeychainPlugin : FlutterPlugin, KeychainPlatformApi {
  override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    KeychainPlatformApi.setUp(binding.binaryMessenger, this)
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    KeychainPlatformApi.setUp(binding.binaryMessenger, null)
  }

  override fun getAll(): List<KeychainData> {
    // TODO implement
    TODO()
  }

  override fun put(item: KeychainData): String {
    // TODO implement
    TODO()
  }

  override fun delete(id: String) {
    // TODO implement
    TODO()
  }

  override fun get(id: String): KeychainData {
    // TODO implement
    TODO()
  }
}

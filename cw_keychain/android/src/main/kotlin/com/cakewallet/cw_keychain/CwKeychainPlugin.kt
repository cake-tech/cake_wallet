package com.cakewallet.cw_keychain

import com.google.android.gms.auth.blockstore.Blockstore
import com.google.android.gms.auth.blockstore.BlockstoreClient
import com.google.android.gms.auth.blockstore.DeleteBytesRequest
import com.google.android.gms.auth.blockstore.RetrieveBytesRequest
import com.google.android.gms.auth.blockstore.StoreBytesData
import com.google.android.gms.common.ConnectionResult
import com.google.android.gms.common.GoogleApiAvailability
import io.flutter.embedding.engine.plugins.FlutterPlugin
import org.json.JSONObject

class CwKeychainPlugin : FlutterPlugin, KeychainPlatformApi {

  private var serviceName = "cw_keychain"
  private var client: BlockstoreClient? = null

  override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    val hasApi = GoogleApiAvailability.getInstance()
      .isGooglePlayServicesAvailable(binding.applicationContext) == ConnectionResult.SUCCESS
    if (hasApi) {
      client = Blockstore.getClient(binding.applicationContext)
    }
    KeychainPlatformApi.setUp(binding.binaryMessenger, this)
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    KeychainPlatformApi.setUp(binding.binaryMessenger, null)
  }

  override fun available(): Boolean {
    return client != null
  }

  override fun put(item: KeychainData, callback: (Result<String>) -> Unit) {
    printWithPrefix("put")
    val accountId = "${serviceName}_${item.name}_${item.walletTypeRaw}"

    try {
      val jsonString = serializeKeychainData(item)
      val data = StoreBytesData.Builder()
        .setKey(accountId)
        .setBytes(jsonString.toByteArray(Charsets.UTF_8))
        .setShouldBackupToCloud(true)
        .build()

      client!!.storeBytes(data)
        .addOnSuccessListener {
          printWithPrefix("put ok: $accountId")
          callback(Result.success(accountId))
        }
        .addOnFailureListener { e ->
          callback(Result.failure(Exception("put fail: ${e.message}")))
        }
    } catch (e: Exception) {
      callback(Result.failure(Exception("serialize fail: ${e.message}")))
    }
  }

  override fun get(id: String, callback: (Result<KeychainData?>) -> Unit) {
    printWithPrefix("get")
    val accountId = "${serviceName}_$id"
    val request = RetrieveBytesRequest.Builder()
      .setKeys(listOf(accountId))
      .build()

    client!!.retrieveBytes(request)
      .addOnSuccessListener { result ->
        try {
          val blockstoreData = result.blockstoreDataMap[accountId]
          if (blockstoreData == null) {
            printWithPrefix("not found: $id")
            callback(Result.success(null))
            return@addOnSuccessListener
          }

          val jsonString = String(blockstoreData.bytes, Charsets.UTF_8)
          val item = deserializeKeychainData(jsonString)

          printWithPrefix("get ok: $id")
          callback(Result.success(item))
        } catch (e: Exception) {
          callback(Result.failure(Exception("decode fail: ${e.message}")))
        }
      }
      .addOnFailureListener { e ->
        callback(Result.failure(Exception("get fail: ${e.message}")))
      }
  }

  override fun delete(id: String, callback: (Result<Unit>) -> Unit) {
    printWithPrefix("delete")
    val accountId = "${serviceName}_$id"
    val request = DeleteBytesRequest.Builder()
      .setKeys(listOf(accountId))
      .build()

    client!!.deleteBytes(request)
      .addOnSuccessListener { _ ->
        printWithPrefix("delete ok: $id")
        callback(Result.success(Unit))
      }
      .addOnFailureListener { e ->
        callback(Result.failure(Exception("delete fail: ${e.message}")))
      }
  }

  override fun getAll(callback: (Result<List<KeychainData>>) -> Unit) {
    printWithPrefix("getAll")
    val request = RetrieveBytesRequest.Builder()
      .setRetrieveAll(true)
      .build()

    client!!.retrieveBytes(request)
      .addOnSuccessListener { result ->
        val results = mutableListOf<KeychainData>()

        for ((key, blockstoreData) in result.blockstoreDataMap) {
          if (key.startsWith(serviceName)) {
            try {
              val jsonString = String(blockstoreData.bytes, Charsets.UTF_8)
              results.add(deserializeKeychainData(jsonString))
              printWithPrefix("decoded ok: $key")
            } catch (e: Exception) {
              printWithPrefix("skip decoding item $key: ${e.message}")
            }
          }
        }
        callback(Result.success(results))
      }
      .addOnFailureListener { e ->
        callback(Result.failure(Exception("getAll fail: ${e.message}")))
      }
  }


  private fun serializeKeychainData(item: KeychainData): String {
    val json = JSONObject()
    json.put("name", item.name)
    json.put("walletTypeRaw", item.walletTypeRaw)
    json.put("seed", item.seed)
    json.put("derivationTypeRaw", item.derivationTypeRaw)
    json.put("derivationPath", item.derivationPath)
    json.put("networkRaw", item.networkRaw)
    json.put("version", item.version)
    item.seedTypeRaw?.let { json.put("seedTypeRaw", it) }
    item.blockHeight?.let { json.put("blockHeight", it) }
    item.passphrase?.let { json.put("passphrase", it) }
    return json.toString()
  }

  private fun deserializeKeychainData(jsonString: String): KeychainData {
    val json = JSONObject(jsonString)
    val name = json.getString("name")
    val walletTypeRaw = json.getLong("walletTypeRaw")
    val seed = json.getString("seed")
    val derivationTypeRaw = json.getLong("derivationTypeRaw")
    val networkRaw = json.getLong("networkRaw")
    val version = json.getLong("version")
    val derivationPath = if (json.has("derivationPath") && !json.isNull("derivationPath")) json.getString("derivationPath") else null
    val seedTypeRaw = if (json.has("seedTypeRaw") && !json.isNull("seedTypeRaw")) json.getLong("seedTypeRaw") else null
    val blockHeight = if (json.has("blockHeight") && !json.isNull("blockHeight")) json.getLong("blockHeight") else null
    val passphrase = if (json.has("passphrase") && !json.isNull("passphrase")) json.getString("passphrase") else null

    return KeychainData(
      version,
      name,
      walletTypeRaw,
      seed,
      networkRaw,
      derivationTypeRaw,
      derivationPath,
      seedTypeRaw,
      blockHeight,
      passphrase
    )
  }

  private fun printWithPrefix(s: String) {
    println("[$serviceName] $s")
  }
}

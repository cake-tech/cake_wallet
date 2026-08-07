package com.cakewallet.cw_keychain

import android.provider.Settings
import com.google.android.gms.auth.blockstore.Blockstore
import com.google.android.gms.auth.blockstore.BlockstoreClient
import com.google.android.gms.auth.blockstore.DeleteBytesRequest
import com.google.android.gms.auth.blockstore.RetrieveBytesRequest
import com.google.android.gms.auth.blockstore.StoreBytesData
import com.google.android.gms.common.ConnectionResult
import com.google.android.gms.common.GoogleApiAvailability
import io.flutter.embedding.engine.plugins.FlutterPlugin
import kotlinx.serialization.json.Json

class CwKeychainPlugin : FlutterPlugin, KeychainPlatformApi {

  private val cloudBackupTransportName = "com.google.android.gms/.backup.BackupTransportService"
  private val serviceName = "cw_keychain"
  private val json = Json { ignoreUnknownKeys = true }
  private var client: BlockstoreClient? = null

  override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    val hasApi = GoogleApiAvailability.getInstance()
      .isGooglePlayServicesAvailable(binding.applicationContext) == ConnectionResult.SUCCESS
    val backupTransportName = Settings.Secure.getString(binding.applicationContext.contentResolver, "backup_transport")
    val hasCloudBackup = backupTransportName == cloudBackupTransportName
    if (hasApi && hasCloudBackup) {
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
    val wrapper = KeychainDataWrapper(item)
    val accountId = "${serviceName}_${wrapper.accountId}"

    try {
      val jsonString = json.encodeToString(wrapper)
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
          val wrapper = json.decodeFromString<KeychainDataWrapper>(jsonString)

          printWithPrefix("get ok: $id")
          callback(Result.success(wrapper.toPigeonData()))
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
              results.add(json.decodeFromString<KeychainDataWrapper>(jsonString).toPigeonData())
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


  private fun printWithPrefix(s: String) {
    println("[$serviceName] $s")
  }
}

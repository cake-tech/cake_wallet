package com.cakewallet.mweb

import androidx.annotation.NonNull

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

import mwebd.Mwebd
import mwebd.Server

/** CwMwebPlugin */
class CwMwebPlugin: FlutterPlugin, MethodCallHandler {
  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private lateinit var channel : MethodChannel
  private var server: Server? = null
  private var port: Long? = null

  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "cw_mweb")
    channel.setMethodCallHandler(this)
  }

  override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
    if (call.method == "start") {
      server?.stop()
      val dataDir = call.argument("dataDir") ?: ""
      val nodeUri = call.argument("nodeUri") ?: ""
      server = server ?: Mwebd.newServer("", dataDir, nodeUri)
      port = server?.start(0)
      result.success(port)
    } else if (call.method == "stop") {
      server?.stop()
      server = null
      port = null
      result.success(null)
    } else if (call.method == "address") {
      // val scanSecret: ByteArray = call.argument<ByteArray>("scanSecret") ?: ByteArray(0)
      // val spendPub: ByteArray = call.argument<ByteArray>("spendPub") ?: ByteArray(0)
      // val index: Int = call.argument<Int>("index") ?: 0
      // val res = Mwebd.address(scanSecret, spendPub, index)
      // result.success(res)
    } else if (call.method == "addresses") {
      val scanSecret: ByteArray = call.argument<ByteArray>("scanSecret") ?: ByteArray(0)
      val spendPub: ByteArray = call.argument<ByteArray>("spendPub") ?: ByteArray(0)
      val fromIndex: Int = call.argument<Int>("fromIndex") ?: 0
      val toIndex: Int = call.argument<Int>("toIndex") ?: 0
      val res = Mwebd.addresses(scanSecret, spendPub, fromIndex, toIndex)
      result.success(res)
    } else {
      result.notImplemented()
    }
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
    server?.stop()
    server = null
    port = null
  }
}

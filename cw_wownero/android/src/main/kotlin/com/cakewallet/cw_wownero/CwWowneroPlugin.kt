package com.cakewallet.cw_wownero

import android.app.Activity
import android.os.AsyncTask
import android.os.Looper
import android.os.Handler
import android.os.Process

import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry.Registrar

class doAsync(val handler: () -> Unit) : AsyncTask<Void, Void, Void>() {
    override fun doInBackground(vararg params: Void?): Void? {
        Process.setThreadPriority(Process.THREAD_PRIORITY_AUDIO);
        handler()
        return null
    }
}

class CwWowneroPlugin: MethodCallHandler {
  companion object {
//    val wowneroApi = WowneroApi()
    val main = Handler(Looper.getMainLooper());

    init {
      System.loadLibrary("cw_wownero")
    }

    @JvmStatic
    fun registerWith(registrar: Registrar) {
      val channel = MethodChannel(registrar.messenger(), "cw_wownero")
      channel.setMethodCallHandler(CwWowneroPlugin())
    }
  }

  override fun onMethodCall(call: MethodCall, result: Result) {
    if (call.method == "setupNode") {
      val uri = call.argument("address") ?: ""
      val login = call.argument("login") ?: ""
      val password = call.argument("password") ?: ""
      val useSSL = false
      val isLightWallet = false
//      doAsync {
//        try {
//          wowneroApi.setNodeAddressJNI(uri, login, password, useSSL, isLightWallet)
//          main.post({
//            result.success(true)
//          });
//        } catch(e: Throwable) {
//          main.post({
//            result.error("CONNECTION_ERROR", e.message, null)
//          });
//        }
//      }.execute()
    }
    if (call.method == "startSync") {
//      doAsync {
//        wowneroApi.startSyncJNI()
//        main.post({
//          result.success(true)
//        });
//      }.execute()
    }
    if (call.method == "loadWallet") {
      val path = call.argument("path") ?: ""
      val password = call.argument("password") ?: ""
//      wowneroApi.loadWalletJNI(path, password)
      result.success(true)
    }
  }
}

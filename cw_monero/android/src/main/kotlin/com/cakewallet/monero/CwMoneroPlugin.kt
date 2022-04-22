package com.cakewallet.monero

import androidx.annotation.NonNull
import android.app.Activity
import android.os.AsyncTask
import android.os.Looper
import android.os.Handler
import android.os.Process

import io.flutter.embedding.engine.plugins.FlutterPlugin
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

class CwMoneroPlugin: FlutterPlugin, MethodCallHandler {
  companion object {
//    val moneroApi = MoneroApi()
    val main = Handler(Looper.getMainLooper());

    init {
      System.loadLibrary("cw_monero")
    }

        @JvmStatic
        fun registerWith(registrar: Registrar) {
            val channel = MethodChannel(registrar.messenger(), "cw_monero")
            channel.setMethodCallHandler(CwMoneroPlugin())
        }
    }
    /// The MethodChannel that will the communication between Flutter and native Android
    ///
    /// This local reference serves to register the plugin with the Flutter Engine and unregister it
    /// when the Flutter Engine is detached from the Activity
    private lateinit var channel : MethodChannel

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "cw_monero")
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        if (call.method == "getPlatformVersion") {
            result.success("Android ${android.os.Build.VERSION.RELEASE}")
        } else if (call.method == "setupNode") {
            val uri = call.argument("address") ?: ""
            val login = call.argument("login") ?: ""
            val password = call.argument("password") ?: ""
            val useSSL = false
            val isLightWallet = false
//      doAsync {
//        try {
//          moneroApi.setNodeAddressJNI(uri, login, password, useSSL, isLightWallet)
//          main.post({
//            result.success(true)
//          });
//        } catch(e: Throwable) {
//          main.post({
//            result.error("CONNECTION_ERROR", e.message, null)
//          });
//        }
//      }.execute()
        } else if (call.method == "startSync") {
//      doAsync {
//        moneroApi.startSyncJNI()
//        main.post({
//          result.success(true)
//        });
//      }.execute()
        } else if (call.method == "loadWallet") {
            val path = call.argument("path") ?: ""
            val password = call.argument("password") ?: ""
//      moneroApi.loadWalletJNI(path, password)
            result.success(true)
        } else {

            result.notImplemented()
        }
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }
}

package com.cakewallet.cw_pivx

import androidx.annotation.NonNull

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/** CwPivxPlugin */
class CwPivxPlugin: FlutterPlugin, MethodCallHandler {
    /// The MethodChannel that will the communication between Flutter and native Android
    ///
    /// This local reference serves to register the plugin with the Flutter Engine and unregister it
    /// when the Flutter Engine is detached from the Activity
    private lateinit var channel : MethodChannel
    private var nativeLibraryLoaded = false
    private var nativeLibraryError: String? = null

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "cw_pivx")
        channel.setMethodCallHandler(this)

        loadSaplingNativeLibrary()
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        when (call.method) {
            "getPlatformVersion" -> {
                result.success("Android ${android.os.Build.VERSION.RELEASE}")
            }
            "isSaplingNativeLoaded" -> {
                result.success(nativeLibraryLoaded)
            }
            "getSaplingNativeLoadError" -> {
                result.success(nativeLibraryError)
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    private fun loadSaplingNativeLibrary() {
        try {
            System.loadLibrary("cw_pivx_sapling")
            nativeLibraryLoaded = true
            nativeLibraryError = null
        } catch (error: UnsatisfiedLinkError) {
            nativeLibraryLoaded = false
            nativeLibraryError = error.message ?: error.javaClass.simpleName
        } catch (error: SecurityException) {
            nativeLibraryLoaded = false
            nativeLibraryError = error.message ?: error.javaClass.simpleName
        }
    }
}

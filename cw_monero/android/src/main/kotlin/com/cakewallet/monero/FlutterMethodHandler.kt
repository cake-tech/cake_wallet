package com.cakewallet.monero

import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel.Result

class FlutterMethodHandler(val name: String, val handler: (MethodCall, Result) -> Unit) {
    fun handle(call: MethodCall, result: Result) {
        if (name == call.method) {
            handler(call, result)
        }
    }
}
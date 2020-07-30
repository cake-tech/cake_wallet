package com.cakewallet.monero

import com.cakewallet.monero.MoneroWalletSyncStatusListener

class MoneroApi {
    private var isLoaded = false

    fun load() : Unit {
        if (isLoaded) {
            return
        }

        System.loadLibrary("cw_monero")
        isLoaded = true
    }

    fun setupListener(listener: MoneroWalletSyncStatusListener) {
        setupListenerJNI(listener)
    }

    external fun setupListenerJNI(listener: MoneroWalletSyncStatusListener)
}
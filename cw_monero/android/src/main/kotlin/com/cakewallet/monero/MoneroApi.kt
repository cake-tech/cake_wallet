package com.cakewallet.monero

import com.cakewallet.monero.MoneroWalletSyncStatusListener

class MoneroApi {

    companion object {
        init {
            System.loadLibrary("cw_monero")
        }
    }

    fun setupListener(listener: MoneroWalletSyncStatusListener) {
        setupListenerJNI(listener)
    }

    external fun setupListenerJNI(listener: MoneroWalletSyncStatusListener)
}
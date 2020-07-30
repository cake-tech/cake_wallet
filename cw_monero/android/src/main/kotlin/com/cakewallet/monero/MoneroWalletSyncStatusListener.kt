package com.cakewallet.monero

class MoneroWalletSyncStatusListener(val onNewBlock: (Long) -> Unit,
                                     val onRefreshed: () -> Unit,
                                     val onUpdated: () -> Unit,
                                     val onMoneySpent: () -> Unit,
                                     val onMoneyReceived: () -> Unit,
                                     val onUnconfirmedMoneyReceived: () -> Unit) {
    fun newBlock(block: Long) {
        onNewBlock(block)
    }

    fun refreshed() {
        onRefreshed()
    }

    fun updated() {
        onUpdated()
    }

    fun moneyReceived() {
        onMoneyReceived()
    }

    fun moneySpent() {
        onMoneySpent()
    }

    fun unconfirmedMoneyReceived() {
        onUnconfirmedMoneyReceived()
    }
}
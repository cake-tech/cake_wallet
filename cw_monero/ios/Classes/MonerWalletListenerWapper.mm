#import <Foundation/Foundation.h>
#import "MoneroWalletListener.h"
#include "monero_api.cpp"

struct MonerWalletListenerWapper: Monero::WalletListener {
    MoneroWalletListener *listener;
    
    void moneySpent(const std::string &txId, uint64_t amount) {
        [listener moneySpent: [NSString stringWithUTF8String: txId.c_str()] amount: amount];
    }
    
    void moneyReceived(const std::string &txId, uint64_t amount) {
        [listener moneyReceived: [NSString stringWithUTF8String: txId.c_str()] amount: amount];
    }
    
    void unconfirmedMoneyReceived(const std::string &txId, uint64_t amount) {
        [listener unconfirmedMoneyReceived: [NSString stringWithUTF8String: txId.c_str()] amount: amount];
    }
    
    void newBlock(uint64_t height) {
        [listener newBlock: height];
    }
    
    void updated() {
        [listener updated];
    }
    
    void refreshed() {
        [listener refreshed];
    }
};

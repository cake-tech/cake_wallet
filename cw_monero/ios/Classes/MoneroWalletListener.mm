#import "MoneroWalletListener.h"
#import "MonerWalletListenerWapper.mm"

@implementation MoneroWalletListener
- (void)setup
{
    MonerWalletListenerWapper *listener = new MonerWalletListenerWapper();
    listener->listener = self;
    get_current_wallet()->setListener(listener);
}

- (void)newBlock:(uint64_t) block
{
    self.onNewBlock(block);
}

- (void)updated
{
    self.onUpdated(nullptr);
}

- (void)refreshed
{
    self.onRefreshed(nullptr);
}

- (void)moneyReceived:(NSString *) txId amount:(uint64_t) amount
{
    self.onMoneyReceived(txId, amount);
}

- (void)moneySpent:(NSString *) txId amount:(uint64_t) amount
{
    self.onMoneySpent(txId, amount);
}

- (void)unconfirmedMoneyReceived:(NSString *) txId amount:(uint64_t) amount
{
    self.onUnconfirmedMoneyReceived(txId, amount);
}

@end

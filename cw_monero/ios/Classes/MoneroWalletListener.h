@interface MoneroWalletListener : NSObject

@property(nonatomic) void (*onNewBlock)(uint64_t);
@property(nonatomic) void (*onUpdated)(void *);
@property(nonatomic) void (*onRefreshed)(void *);
@property(nonatomic) void (*onMoneyReceived) (NSString *, uint64_t);
@property(nonatomic) void (*onMoneySpent) (NSString *, uint64_t);
@property(nonatomic) void (*onUnconfirmedMoneyReceived) (NSString *, uint64_t);

- (void)setup;
- (void)newBlock:(uint64_t) block;
- (void)updated;
- (void)refreshed;
- (void)moneyReceived:(NSString *) txId amount:(uint64_t) amount;
- (void)moneySpent:(NSString *) txId amount:(uint64_t) amount;
- (void)unconfirmedMoneyReceived:(NSString *) txId amount:(uint64_t) amount;

@end

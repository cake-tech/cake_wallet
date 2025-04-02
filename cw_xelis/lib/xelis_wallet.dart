import 'package:mobx/mobx.dart';
import 'package:cw_xelis/src/api/wallet.dart' as x_wallet;

part 'xelis_wallet.g.dart';

class XelisWallet = XelisWalletBase with _$XelisWallet;

abstract class XelisWalletBase 
  extends WalletBase<XelisBalance,
    XelisTransactionHistory, XelisTransactionInfo
> {
  final x_wallet.XelisWallet wallet;

  XelisWalletBase({
    required WalletInfo walletInfo,
    required this.wallet,
  }) : isOnline = false,
       xelisBalance = BigInt.zero,
       address = '',
       super(walletInfo) {
    transactionHistory = XelisTransactionHistory();
    _setupReactions();
    _init();
  }

  @observable
  bool isOnline;

  @observable
  BigInt xelisBalance;

  @observable
  String address;

  @override
  late final XelisTransactionHistory transactionHistory;

  @action
  Future<void> _init() async {
    try {
      address = wallet.getAddressStr();
      isOnline = await wallet.isOnline();
      xelisBalance = await wallet.getXelisBalanceRaw();
      // Optionally update history right away
    } catch (e) {
      // log or handle errors
    }
  }

  ReactionDisposer? _balanceReaction;
  ReactionDisposer? _onlineStatusReaction;

  void _setupReactions() {
    // example if you add observables like `walletStatus` or config settings
    // _balanceReaction = reaction((_) => someTrigger, (_) => refreshBalance());
  }

  @action
  Future<void> refreshBalance() async {
    xelisBalance = await wallet.getXelisBalanceRaw();
  }

  @action
  Future<void> goOnline(String daemon) async {
    await wallet.onlineMode(daemonAddress: daemon);
    isOnline = await wallet.isOnline();
  }

  @action
  Future<void> goOffline() async {
    await wallet.offlineMode();
    isOnline = await wallet.isOnline();
  }

  @override
  Future<void> close({bool shouldCleanup = false}) async {
    await wallet.close();
    _balanceReaction?.call();
    _onlineStatusReaction?.call();
  }
}
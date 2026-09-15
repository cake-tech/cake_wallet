import "dart:async";

import "package:cake_wallet/store/app_store.dart";
import "package:cw_core/wallet_base.dart";
import "package:mobx/mobx.dart" as mobx;

class ActiveWalletService {
  ActiveWalletService(this._appStore) {
    _disposeReaction = mobx.reaction(
      (_) => _appStore.wallet,
      (next) {
        if (next != null) {
          _controller.add(next);
        }
      },
    );
  }

  final AppStore _appStore;
  final StreamController<WalletBase> _controller = StreamController<WalletBase>.broadcast();
  late final mobx.ReactionDisposer _disposeReaction;

  WalletBase get wallet {
    final wallet = _appStore.wallet;
    if (wallet == null) {
      throw StateError(
        "No wallet is active yet",
      );
    }
    return wallet;
  }

  Stream<WalletBase> get walletChanges => _controller.stream;

  Future<void> dispose() async {
    _disposeReaction();
    await _controller.close();
  }
}

import 'package:cake_wallet/core/execution_state.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:mobx/mobx.dart';

part 'sign_view_model.g.dart';

class SignViewModel = SignViewModelBase with _$SignViewModel;

abstract class SignViewModelBase with Store {
  SignViewModelBase(this.wallet) : state = InitialExecutionState();

  final WalletBase wallet;

  @observable
  ExecutionState state;

  @observable
  bool isSigning = true;

  bool get signIncludesAddress => [
        WalletType.monero,
        WalletType.bitcoin,
        WalletType.bitcoinCash,
        WalletType.litecoin,
        WalletType.dogecoin,
        WalletType.haven,
      ].contains(wallet.type);

  @action
  Future<void> sign(String message, {String? address}) async {
    state = IsExecutingState();
    try {
      final signature = await wallet.signMessage(message, address: address);
      state = ExecutedSuccessfullyState(payload: signature);
    } catch (e) {
      state = FailureState(e.toString());
    }
  }

  @action
  Future<void> verify(String message, String signature, {String? address}) async {
    state = IsExecutingState();
    try {
      final sig = await wallet.verifyMessage(message, signature, address: address);
      if (sig) {
        state = ExecutedSuccessfullyState();
      } else {
        state = FailureState(S.current.signature_invalid_error);
      }
    } catch (e) {
      state = FailureState(e.toString());
    }
  }
}

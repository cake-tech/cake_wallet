import "package:bloc/bloc.dart";
import "package:bloc_concurrency/bloc_concurrency.dart";
import "package:cake_wallet/bitcoin/bitcoin.dart";
import "package:cake_wallet/entities/spark_conversion.dart";
import "package:cake_wallet/utils/token_utilities.dart";
import "package:cake_wallet/view_model/dashboard/home_settings_view_model.dart";
import "package:cw_core/amount/money.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/utils/print_verbose.dart";
import "package:cw_core/wallet_base.dart";
import "package:meta/meta.dart";

part "spark_stable_balance_send_event.dart";
part "spark_stable_balance_send_state.dart";

typedef LightningSendQuoter = Future<LightningSendQuote> Function(
  String address,
  Money amount, {
  bool sendAll,
});

/// Live quote for a Lightning send while Stable Balance is on: what the recipient gets, and what
/// it costs in the stablecoin the SDK converts from when the sats balance is short.
class SparkStableBalanceSendBloc extends Bloc<SparkStableBalanceSendEvent, SparkStableBalanceSendState> {
  SparkStableBalanceSendBloc({
    required WalletBase wallet,
    required LightningSendQuoter quote,
    this.quoteDebounce = const Duration(milliseconds: 500),
  })  : _wallet = wallet,
        _quote = quote,
        super(SparkStableBalanceSendNotLoaded()) {
    on<SendDetailsChanged>(_onSendDetailsChanged, transformer: restartable());
  }

  final WalletBase _wallet;
  final LightningSendQuoter _quote;

  /// How long typing has to pause before a quote is fetched.
  final Duration quoteDebounce;

  /// The slippage the SDK was connected with - see `LightningWallet.defaultMaxSlippageBps`.
  int get maxSlippageBps =>
      bitcoin?.getStableBalanceMaxSlippageBps(_wallet) ??
      HomeSettingsViewModelBase.defaultMaxSlippageBps;

  /// The stablecoin Stable Balance converts from, or null if this wallet has none.
  CryptoCurrency? get stableToken => TokenUtilities.stableBalanceTokenFor(_wallet);

  Money? get stableTokenBalance {
    final token = stableToken;
    return token == null ? null : _wallet.balance[token]?.available;
  }

  Future<void> _onSendDetailsChanged(
    SendDetailsChanged event,
    Emitter<SparkStableBalanceSendState> emit,
  ) async {
    final address = event.address.trim();
    final amount = event.amount;
    if (address.isEmpty || amount == null || amount.amount <= BigInt.zero) {
      emit(SparkStableBalanceSendNotLoaded());
      return;
    }

    emit(SparkStableBalanceSendQuoting());
    // restartable() closes this run's emitter when newer details arrive, which is the debounce.
    await Future<void>.delayed(quoteDebounce);
    if (emit.isDone) {
      return;
    }

    try {
      emit(SparkStableBalanceSendQuoted(await _quote(address, amount, sendAll: event.sendAll)));
    } catch (e) {
      printV("StableBalanceSend: quote failed: $e");
      emit(SparkStableBalanceSendQuoteFailed(e.toString()));
    }
  }
}

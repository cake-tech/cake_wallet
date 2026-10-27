import "package:bitcoin_base/bitcoin_base.dart";
import "package:cw_bitcoin/bitcoin_address_record.dart";
import "package:cw_bitcoin/bitcoin_unspent.dart";
import "package:cw_bitcoin/electrum_balance.dart";
import "package:cw_core/amount/money.dart";
import "package:cw_core/crypto_currency.dart";

class AccountBalanceCalculator {
  AccountBalanceCalculator._();

  static Map<int, ElectrumBalance> fromCoins(
    Iterable<BitcoinUnspent> coins, {
    required CryptoCurrency currency,
  }) {
    final confirmed = <int, int>{};
    final unconfirmed = <int, int>{};
    final frozen = <int, int>{};

    for (final coin in coins) {
      final account = coin.bitcoinAddressRecord.accountIndex;

      if (coin.isFrozen) _add(frozen, account, coin.value);

      if ((coin.confirmations ?? 0) > 0) {
        _add(confirmed, account, coin.value);
      } else {
        _add(unconfirmed, account, coin.value);
      }
    }

    return fromTotals(
      confirmed: confirmed,
      unconfirmed: unconfirmed,
      frozen: frozen,
      currency: currency,
    );
  }

  static Map<int, ElectrumBalance> fromAddressRecords(
    Iterable<BaseBitcoinAddressRecord> records, {
    required CryptoCurrency currency,
  }) {
    final confirmed = <int, int>{};

    for (final record in records) {
      if (record.type == SegwitAddresType.mweb) continue;
      _add(confirmed, record.accountIndex, record.balance);
    }

    return fromTotals(confirmed: confirmed, currency: currency);
  }

  static Map<int, ElectrumBalance> fromTotals({
    Map<int, int> confirmed = const {},
    Map<int, int> unconfirmed = const {},
    Map<int, int> frozen = const {},
    required CryptoCurrency currency,
  }) {
    final accounts = <int>{...confirmed.keys, ...unconfirmed.keys, ...frozen.keys};

    return {
      for (final account in accounts)
        account: ElectrumBalance(
          confirmed: Money.fromInt(confirmed[account] ?? 0, currency),
          unconfirmed: Money.fromInt(unconfirmed[account] ?? 0, currency),
          frozen: Money.fromInt(frozen[account] ?? 0, currency),
        ),
    };
  }

  static void _add(Map<int, int> totals, int account, int sats) =>
      totals.update(account, (value) => value + sats, ifAbsent: () => sats);
}

import 'package:cake_wallet/ask_cake/ask_cake_tools.dart';
import 'package:cake_wallet/entities/contact.dart';
import 'package:cake_wallet/entities/transaction_description.dart';
import 'package:cake_wallet/exchange/exchange_provider_description.dart';
import 'package:cake_wallet/exchange/trade.dart';
import 'package:cake_wallet/exchange/trade_state.dart';
import 'package:cake_wallet/store/app_store.dart';
import 'package:cake_wallet/store/dashboard/fiat_conversion_store.dart';
import 'package:cw_core/cake_hive.dart';
import 'package:cw_core/amount/money.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/transaction_direction.dart';
import 'package:cw_core/transaction_info.dart';

/// DEMO ONLY (debug builds): gives the open wallet some contacts, swaps and
/// transaction notes so Ask Cake has something to answer about. Real
/// transactions are left alone; only notes are attached to them.
class AskCakeDemoData {
  static const _marker = 'askcake-demo-';

  static const _outgoingNotes = [
    'Coffee beans order', 'VPN renewal', 'Sent to Alice', 'Cake Pay gift card', 'Sent to Bob', //
    'Swap to BTC', 'Domain renewal', 'Sent to Alice', 'Swap to XMR', 'Hosting',
  ];
  static const _incomingNotes = [
    'Swap from XMR', 'Freelance invoice 114', 'Freelance invoice 113', 'Refund', //
    'Freelance invoice 112', 'Gift from Carol',
  ];

  static Future<String> seed(AppStore appStore, FiatConversionStore fiatConversionStore) async {
    final wallet = appStore.wallet;
    if (wallet == null) return 'No wallet is open.';
    final currency = wallet.currency;

    // Contacts. Alice points at this wallet's own address so a prepared send is
    // harmless; the other addresses are checksum-valid but belong to nobody.
    final contacts = CakeHive.box<Contact>(Contact.boxName);
    final existing = contacts.values.map((c) => c.name).toSet();
    final demoContacts = [
      Contact(name: 'Alice', address: wallet.walletAddresses.address, type: currency),
      Contact(name: 'Bob', address: 'ltc1qsxmr0k8u6trd5c6eu6trzyapzux7090yr6szpw', type: CryptoCurrency.ltc),
      Contact(
          name: 'Carol',
          address:
              '888tNkZrPN6JsEgekjMnABU4TBzc2Dt29EPAvkRxbANsAnjyPbb3iQ1YBRk1UXcdRsiKc9dhwMVgN5S9cQUiyoogDavup3H',
          type: CryptoCurrency.xmr),
      Contact(
          name: 'Dave Exchange',
          address: 'bc1qw508d6qejxtdg4y5r3zarvary0c5xw7kv8f3t4',
          type: CryptoCurrency.btc),
    ];
    var addedContacts = 0;
    for (final contact in demoContacts) {
      if (existing.contains(contact.name)) continue;
      await contacts.add(contact);
      addedContacts++;
    }

    // Swaps, dated relative to today.
    final now = DateTime.now();
    final have = (await Trade.getAll()).map((t) => t.id).toSet();
    final demoTrades = [
      (4, ExchangeProviderDescription.trocador, CryptoCurrency.xmr, '0.62', CryptoCurrency.ltc, '1.10', TradeState.complete),
      (47, ExchangeProviderDescription.changeNow, CryptoCurrency.ltc, '1.40', CryptoCurrency.btc, '0.00128', TradeState.complete),
      (67, ExchangeProviderDescription.sideShift, CryptoCurrency.btc, '0.0021', CryptoCurrency.xmr, '0.71', TradeState.complete),
      (99, ExchangeProviderDescription.trocador, CryptoCurrency.ltc, '0.90', CryptoCurrency.xmr, '0.47', TradeState.complete),
      (139, ExchangeProviderDescription.exolix, CryptoCurrency.usdt, '150.0', CryptoCurrency.xmr, '0.93', TradeState.failed),
    ];
    var addedTrades = 0;
    for (var i = 0; i < demoTrades.length; i++) {
      final (daysAgo, provider, from, amount, to, receiveAmount, state) = demoTrades[i];
      final id = '$_marker$i';
      if (have.contains(id)) continue;
      await Trade(
        id: id,
        depositAmount: Money.safeParse(amount, from),
        payoutAmount: Money.safeParse(receiveAmount, to),
        provider: provider,
        state: state,
        fundingAddress: '',
        payoutAddress: '',
        refundAddress: '',
        createdAt: now.subtract(Duration(days: daysAgo)),
        walletId: wallet.id,
      ).save();
      addedTrades++;
    }

    // Notes on the wallet's real transactions, newest first.
    final descriptions = CakeHive.box<TransactionDescription>(TransactionDescription.boxName);
    final noted = descriptions.values.map((d) => d.id.split('_').first).toSet();
    final txs = (wallet.transactionHistory.transactions.values as Iterable).cast<TransactionInfo>().toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    var addedNotes = 0;
    var outgoing = 0;
    var incoming = 0;
    for (final tx in txs) {
      final isIncoming = tx.direction == TransactionDirection.incoming;
      final pool = isIncoming ? _incomingNotes : _outgoingNotes;
      final index = isIncoming ? incoming++ : outgoing++;
      if (index >= pool.length || noted.contains(tx.txHash)) continue;
      await descriptions.add(TransactionDescription(id: tx.txHash, transactionNote: pool[index]));
      addedNotes++;
    }

    // Local builds have no fiat API key; fall back to a fixed demo price.
    var priced = '';
    if ((fiatConversionStore.prices[currency] ?? 0) == 0) {
      fiatConversionStore.prices[currency] = 92.40;
      priced = ', demo price set';
    }

    AskCakeTools.demoIgnoreBalance = true;

    return 'Demo data: $addedContacts contacts, $addedTrades swaps, $addedNotes transaction notes added$priced.';
  }
}

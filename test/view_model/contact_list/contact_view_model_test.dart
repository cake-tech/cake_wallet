import 'dart:async';

import 'package:cake_wallet/core/address_resolver/address_resolver_service.dart';
import 'package:cake_wallet/core/address_resolver/address_sources.dart';
import 'package:cake_wallet/core/address_resolver/parsed_address.dart';
import 'package:cake_wallet/entities/contact.dart';
import 'package:cake_wallet/store/app_store.dart';
import 'package:cake_wallet/view_model/contact_list/contact_view_model.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mocktail/mocktail.dart';

class _MockContacts extends Mock implements Box<Contact> {}

class _MockAppStore extends Mock implements AppStore {}

class _MockResolver extends Mock implements AddressResolverService {}

class _MockWallet extends Mock implements WalletBase {}

class _MockContext extends Mock implements BuildContext {}

void main() {
  late _MockAppStore appStore;
  late _MockResolver resolver;
  late ContactViewModel viewModel;

  setUp(() {
    appStore = _MockAppStore();
    resolver = _MockResolver();
    viewModel = ContactViewModel(_MockContacts(), appStore, resolver);
    viewModel.name = 'Alice';
    viewModel.address = 'd/alice';
  });

  test('resolves before an upfront currency selection', () async {
    final wallet = _MockWallet();
    const parsed = ParsedAddress(
      parsedAddressByCurrencyMap: {CryptoCurrency.btc: 'bc1-main'},
      addressSource: AddressSource.namecoin,
      handle: 'd/alice',
    );
    when(() => appStore.wallet).thenReturn(wallet);
    when(
      () => resolver.resolve(query: 'd/alice', wallet: wallet, currency: null),
    ).thenAnswer((_) async => [parsed]);

    final result = await viewModel.extractParsedAddress(_MockContext());
    expect(result, same(parsed));
  });

  test('resolves a Namecoin alias even when it resembles a raw address', () async {
    final wallet = _MockWallet();
    const parsed = ParsedAddress(
      parsedAddressByCurrencyMap: {CryptoCurrency.hbar: '0.0.123'},
      addressSource: AddressSource.namecoin,
      handle: 'd/alice',
    );
    viewModel.currency = CryptoCurrency.hbar;
    viewModel.address = 'alice.bit';
    when(() => appStore.wallet).thenReturn(wallet);
    when(
      () => resolver.resolve(
        query: 'alice.bit',
        wallet: wallet,
        currency: CryptoCurrency.hbar,
      ),
    ).thenAnswer((_) async => [parsed]);

    final result = await viewModel.extractParsedAddress(_MockContext());
    expect(result, same(parsed));
  });

  test('shows only currencies present and refuses an absent selection', () {
    viewModel.applyParsedAddress(
      const ParsedAddress(
        parsedAddressByCurrencyMap: {
          CryptoCurrency.btc: 'bc1-main',
          CryptoCurrency.xmr: '4abc',
        },
        addressSource: AddressSource.namecoin,
        handle: 'd/alice',
      ),
    );

    expect(viewModel.currency, isNull);
    expect(viewModel.address, 'd/alice');
    expect(viewModel.currencies, [CryptoCurrency.xmr, CryptoCurrency.btc]);

    viewModel.selectCurrency(CryptoCurrency.doge);
    expect(viewModel.currency, isNull);
    expect(viewModel.address, 'd/alice');

    viewModel.selectCurrency(CryptoCurrency.btc);
    expect(viewModel.currency, CryptoCurrency.btc);
    expect(viewModel.address, 'bc1-main');

    viewModel.selectCurrency(CryptoCurrency.doge);
    expect(viewModel.currency, CryptoCurrency.btc);
    expect(viewModel.address, 'bc1-main');
  });

  test('selects a single available currency automatically', () {
    viewModel.applyParsedAddress(
      const ParsedAddress(
        parsedAddressByCurrencyMap: {CryptoCurrency.xmr: '4abc'},
        addressSource: AddressSource.namecoin,
      ),
    );

    expect(viewModel.currency, CryptoCurrency.xmr);
    expect(viewModel.address, '4abc');
    expect(viewModel.currencies, [CryptoCurrency.xmr]);
    expect(viewModel.isReady, isTrue);
  });

  test('does not substitute a sole currency for an explicit absent selection', () {
    viewModel.currency = CryptoCurrency.doge;
    viewModel.applyParsedAddress(
      const ParsedAddress(
        parsedAddressByCurrencyMap: {CryptoCurrency.xmr: '4abc'},
        addressSource: AddressSource.namecoin,
        handle: 'd/alice',
      ),
    );

    expect(viewModel.currency, isNull);
    expect(viewModel.address, 'd/alice');
    expect(viewModel.currencies, [CryptoCurrency.xmr]);
    expect(viewModel.isReady, isFalse);
  });

  test('keeps a selected currency only when the record contains it', () {
    viewModel.currency = CryptoCurrency.xmr;
    viewModel.applyParsedAddress(
      const ParsedAddress(
        parsedAddressByCurrencyMap: {
          CryptoCurrency.btc: 'bc1-main',
          CryptoCurrency.xmr: '4abc',
        },
        addressSource: AddressSource.namecoin,
      ),
    );

    expect(viewModel.currency, CryptoCurrency.xmr);
    expect(viewModel.address, '4abc');
    viewModel.selectCurrency(CryptoCurrency.btc);
    expect(viewModel.address, 'bc1-main');
  });

  test('editing the resolved value restores unrestricted currency choices', () {
    viewModel.applyParsedAddress(
      const ParsedAddress(
        parsedAddressByCurrencyMap: {CryptoCurrency.btc: 'bc1-main'},
        addressSource: AddressSource.namecoin,
        handle: 'd/alice',
      ),
    );

    viewModel.updateAddress('d/other');
    expect(viewModel.currencies, CryptoCurrency.all);
    expect(viewModel.displayName, isEmpty);
  });

  test('allows a save attempt for an unresolved Namecoin alias without a currency', () {
    expect(viewModel.isReady, isFalse);
    expect(viewModel.canAttemptSave, isTrue);
    viewModel.address = 'example.com';
    expect(viewModel.canAttemptSave, isFalse);
  });

  test('does not save an unresolved Namecoin identifier as a raw address', () {
    viewModel.currency = CryptoCurrency.hbar;
    viewModel.address = 'alice.bit';

    expect(viewModel.canAttemptSave, isTrue);
    expect(viewModel.isReady, isFalse);
  });

  test('discards a lookup result after the alias is edited', () async {
    final wallet = _MockWallet();
    final completer = Completer<List<ParsedAddress>>();
    const parsed = ParsedAddress(
      parsedAddressByCurrencyMap: {CryptoCurrency.btc: 'bc1-main'},
      addressSource: AddressSource.namecoin,
      handle: 'd/alice',
    );
    when(() => appStore.wallet).thenReturn(wallet);
    when(
      () => resolver.resolve(query: 'd/alice', wallet: wallet, currency: null),
    ).thenAnswer((_) => completer.future);

    final result = viewModel.extractParsedAddress(_MockContext());
    viewModel.updateAddress('d/other');
    completer.complete([parsed]);

    expect(await result, isNull);
    expect(viewModel.address, 'd/other');
    expect(viewModel.currency, isNull);
  });

  test('discards a lookup result after the selected currency changes', () async {
    final wallet = _MockWallet();
    final completer = Completer<List<ParsedAddress>>();
    const parsed = ParsedAddress(
      parsedAddressByCurrencyMap: {CryptoCurrency.btc: 'bc1-main'},
      addressSource: AddressSource.namecoin,
      handle: 'd/alice',
    );
    when(() => appStore.wallet).thenReturn(wallet);
    when(
      () => resolver.resolve(query: 'd/alice', wallet: wallet, currency: null),
    ).thenAnswer((_) => completer.future);

    final result = viewModel.extractParsedAddress(_MockContext());
    viewModel.selectCurrency(CryptoCurrency.doge);
    completer.complete([parsed]);

    expect(await result, isNull);
    expect(viewModel.currency, CryptoCurrency.doge);
    expect(viewModel.address, 'd/alice');
  });
}

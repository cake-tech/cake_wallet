import 'dart:async';

import 'package:cake_wallet/core/address_resolver/address_sources.dart';
import 'package:cake_wallet/core/address_resolver/parsed_address.dart';
import 'package:cake_wallet/store/app_store.dart';
import 'package:cake_wallet/store/dashboard/fiat_conversion_store.dart';
import 'package:cake_wallet/view_model/send/output.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/sync_status.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobx/mobx.dart' hide Output;
import 'package:mocktail/mocktail.dart';

class _MockWallet extends Mock implements WalletBase {}

class _MockAppStore extends Mock implements AppStore {}

class _MockFiatConversionStore extends Mock implements FiatConversionStore {}

void main() {
  late Output output;
  late CryptoCurrency activeCurrency;

  setUp(() {
    activeCurrency = CryptoCurrency.btc;
    final wallet = _MockWallet();
    when(() => wallet.syncStatus).thenReturn(const NotConnectedSyncStatus());
    output = Output(
      wallet,
      _MockAppStore(),
      _MockFiatConversionStore(),
      ([CryptoCurrency? _]) => activeCurrency,
    );
    output.address = 'd/alice';
  });

  test('does not apply an address from another currency', () {
    output.applyAddressLookupResult(
      const ParsedAddress(
        parsedAddressByCurrencyMap: {CryptoCurrency.xmr: '4abc'},
        addressSource: AddressSource.namecoin,
        handle: 'd/alice',
      ),
    );

    expect(output.address, 'd/alice');
    expect(output.extractedAddress, isEmpty);
    expect(output.displayName, isNull);
    expect(output.isParsedAddress, isFalse);
  });

  test('a missing active currency clears a previously resolved address', () {
    output.applyAddressLookupResult(
      const ParsedAddress(
        parsedAddressByCurrencyMap: {CryptoCurrency.btc: 'bc1-main'},
        addressSource: AddressSource.namecoin,
        handle: 'd/alice',
      ),
    );
    expect(output.extractedAddress, 'bc1-main');
    expect(output.isParsedAddress, isTrue);

    output.applyAddressLookupResult(
      const ParsedAddress(
        parsedAddressByCurrencyMap: {CryptoCurrency.xmr: '4abc'},
        addressSource: AddressSource.namecoin,
        handle: 'd/alice',
      ),
    );

    expect(output.extractedAddress, isEmpty);
    expect(output.displayName, isNull);
    expect(output.isParsedAddress, isFalse);
    expect(output.address, 'd/alice');
  });

  test('changing currency invalidates the extracted recipient and restores the alias', () {
    output.applyAddressLookupResult(
      const ParsedAddress(
        parsedAddressByCurrencyMap: {
          CryptoCurrency.btc: 'bc1-main',
          CryptoCurrency.xmr: '4abc',
        },
        addressSource: AddressSource.namecoin,
        handle: 'd/alice',
      ),
    );
    expect(output.isParsedAddress, isTrue);

    activeCurrency = CryptoCurrency.xmr;
    expect(output.isParsedAddress, isFalse);
    output.invalidateForCurrencyChange();

    expect(output.address, 'd/alice');
    expect(output.extractedAddress, isEmpty);
    expect(output.displayName, isNull);
    expect(output.isParsedAddress, isFalse);
  });

  test('editing an input invalidates an in-flight lookup generation', () {
    final generation = output.addressLookupGeneration;
    expect(
      output.isAddressLookupCurrent(
        query: 'd/alice',
        currency: CryptoCurrency.btc,
        generation: generation,
      ),
      isTrue,
    );

    output.resetParsedAddress();
    output.address = 'd/other';

    expect(
      output.isAddressLookupCurrent(
        query: 'd/alice',
        currency: CryptoCurrency.btc,
        generation: generation,
      ),
      isFalse,
    );
  });

  test('a slower lookup cannot overwrite a newer accepted result for the same input', () async {
    final generation = output.addressLookupGeneration;
    final olderReady = Completer<void>();
    final newerReady = Completer<void>();

    Future<bool> completeLookup(Completer<void> ready, String address) async {
      await ready.future;
      return output.applyAddressLookupResult(
        ParsedAddress(
          parsedAddressByCurrencyMap: {CryptoCurrency.btc: address},
          addressSource: AddressSource.namecoin,
          handle: 'd/alice',
        ),
        expectedGeneration: generation,
      );
    }

    final older = completeLookup(olderReady, 'bc1-old');
    final newer = completeLookup(newerReady, 'bc1-new');
    newerReady.complete();
    expect(await newer, isTrue);
    olderReady.complete();
    expect(await older, isFalse);
    expect(output.extractedAddress, 'bc1-new');
  });

  test('currency invalidation notifies the address controller to restore the alias', () {
    final controller = TextEditingController(text: output.address);
    final dispose = reaction<int>(
      (_) => output.addressInvalidationGeneration,
      (_) => controller.text = output.address,
    );
    addTearDown(() {
      dispose();
      controller.dispose();
    });
    output.applyAddressLookupResult(
      const ParsedAddress(
        parsedAddressByCurrencyMap: {CryptoCurrency.btc: 'bc1-main'},
        addressSource: AddressSource.namecoin,
        handle: 'd/alice',
      ),
    );
    controller.text = output.extractedAddress;
    expect(controller.text, 'bc1-main');

    output.invalidateForCurrencyChange();

    expect(controller.text, 'd/alice');
  });
}

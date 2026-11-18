import "dart:async";

import "package:cake_wallet/entities/fiat_api_mode.dart";
import "package:cake_wallet/entities/fiat_currency.dart";
import "package:cake_wallet/store/dashboard/fiat_conversion_store.dart";
import "package:cake_wallet/store/settings_store.dart";
import "package:cw_core/crypto_currency.dart";
import "package:flutter_test/flutter_test.dart";
import "package:mobx/mobx.dart" show Observable, runInAction;
import "package:mocktail/mocktail.dart";

class _MockSettingsStore extends Mock implements SettingsStore {}

class _Request {
  _Request(this.crypto, this.fiat, {required this.torOnly});

  final CryptoCurrency crypto;
  final FiatCurrency fiat;
  final bool torOnly;
  final result = Completer<double>();
}

void main() {
  late Observable<FiatCurrency> fiat;
  late Observable<FiatApiMode> mode;
  late List<_Request> requests;
  late FiatConversionStore store;

  setUp(() {
    final settings = _MockSettingsStore();
    fiat = Observable(FiatCurrency.usd);
    mode = Observable(FiatApiMode.enabled);
    requests = [];
    when(() => settings.fiatCurrency).thenAnswer((_) => fiat.value);
    when(() => settings.fiatApiMode).thenAnswer((_) => mode.value);
    store = FiatConversionStore(
      settingsStore: settings,
      fetchPrice: ({required crypto, required fiat, required torOnly}) {
        final request = _Request(crypto, fiat, torOnly: torOnly);
        requests.add(request);
        return request.result.future;
      },
    );
  });

  tearDown(() => store.dispose());

  Future<void> load(CryptoCurrency crypto, double price) async {
    final loaded = store.fetchPrice(crypto);
    requests.last.result.complete(price);
    await loaded;
  }

  test("changing fiat invalidates cached swap assets without requiring a wallet", () async {
    await load(CryptoCurrency.xmr, 300);
    runInAction(() => fiat.value = FiatCurrency.uah);
    expect(store.prices[CryptoCurrency.xmr], isNull);
    expect(requests.last.fiat, FiatCurrency.uah);
    final refreshed = store.fetchPrice(CryptoCurrency.xmr);
    requests.last.result.complete(12000);
    await refreshed;
    expect(store.prices[CryptoCurrency.xmr], 12000);

    runInAction(() => fiat.value = FiatCurrency.usd);
    expect(store.prices[CryptoCurrency.xmr], isNull);
    final restored = store.fetchPrice(CryptoCurrency.xmr);
    requests.last.result.complete(301);
    await restored;
    expect(store.prices[CryptoCurrency.xmr], 301);
  });

  test("refreshes both requested swap assets, including an external deposit", () async {
    await load(CryptoCurrency.eth, 2000);
    await load(CryptoCurrency.xmr, 300);
    runInAction(() => fiat.value = FiatCurrency.uah);
    expect(store.prices, isEmpty);
    expect(
      requests.skip(2).map((request) => request.crypto),
      containsAll([CryptoCurrency.eth, CryptoCurrency.xmr]),
    );
    final deposit = store.fetchPrice(CryptoCurrency.eth);
    final receive = store.fetchPrice(CryptoCurrency.xmr);
    requests[2].result.complete(80000);
    requests[3].result.complete(12000);
    await Future.wait([deposit, receive]);
    expect(store.prices[CryptoCurrency.eth], 80000);
    expect(store.prices[CryptoCurrency.xmr], 12000);
  });

  test("a first request pending during a fiat change cannot publish an old rate", () async {
    final old = store.fetchPrice(CryptoCurrency.xmr);
    runInAction(() => fiat.value = FiatCurrency.uah);
    final current = store.fetchPrice(CryptoCurrency.xmr);
    expect(requests.length, 2);
    requests[1].result.complete(12000);
    await current;
    requests[0].result.complete(300);
    await old;
    expect(store.prices[CryptoCurrency.xmr], 12000);
  });

  test("USD to UAH to USD rejects the first USD response", () async {
    final first = store.fetchPrice(CryptoCurrency.xmr);
    runInAction(() => fiat.value = FiatCurrency.uah);
    final middle = store.fetchPrice(CryptoCurrency.xmr);
    runInAction(() => fiat.value = FiatCurrency.usd);
    final last = store.fetchPrice(CryptoCurrency.xmr);
    requests[2].result.complete(310);
    await last;
    requests[0].result.complete(300);
    requests[1].result.complete(12000);
    await Future.wait([first, middle]);
    expect(store.prices[CryptoCurrency.xmr], 310);
  });

  test("coalesces pending requests and reuses a successful same-fiat cache", () async {
    final first = store.fetchPrice(CryptoCurrency.xmr);
    final second = store.fetchPrice(CryptoCurrency.xmr, force: true);
    expect(requests.length, 1);
    requests.single.result.complete(300);
    await Future.wait([first, second]);
    await store.fetchPrice(CryptoCurrency.xmr);
    expect(requests.length, 1);
    expect(store.prices[CryptoCurrency.xmr], 300);
  });

  test("forced refresh replaces a successful same-fiat price", () async {
    await load(CryptoCurrency.xmr, 300);
    final refreshed = store.fetchPrice(CryptoCurrency.xmr, force: true);
    requests.last.result.complete(310);
    await refreshed;
    expect(store.prices[CryptoCurrency.xmr], 310);
  });

  for (final invalid in [0.0, -1.0, double.nan, double.infinity]) {
    test("invalid price $invalid remains unavailable and can be retried", () async {
      await load(CryptoCurrency.xmr, invalid);
      expect(store.prices[CryptoCurrency.xmr], isNull);
      await load(CryptoCurrency.xmr, 300);
      expect(store.prices[CryptoCurrency.xmr], 300);
    });
  }

  test("failed refresh preserves a valid same-fiat price", () async {
    await load(CryptoCurrency.xmr, 300);
    final refresh = store.fetchPrice(CryptoCurrency.xmr, force: true);
    requests.last.result.completeError(StateError("offline"));
    await refresh;
    expect(store.prices[CryptoCurrency.xmr], 300);
    final retry = store.fetchPrice(CryptoCurrency.xmr, force: true);
    requests.last.result.complete(310);
    await retry;
    expect(store.prices[CryptoCurrency.xmr], 310);
  });

  test("a synchronous fetch error does not leave a permanently pending request", () async {
    final settings = _MockSettingsStore();
    when(() => settings.fiatCurrency).thenReturn(FiatCurrency.usd);
    when(() => settings.fiatApiMode).thenReturn(FiatApiMode.enabled);
    var attempts = 0;
    final failing = FiatConversionStore(
      settingsStore: settings,
      fetchPrice: ({required crypto, required fiat, required torOnly}) {
        if (attempts++ == 0) {
          throw StateError("offline");
        }
        return Future.value(300);
      },
    );
    addTearDown(failing.dispose);
    await failing.fetchPrice(CryptoCurrency.xmr);
    await failing.fetchPrice(CryptoCurrency.xmr);
    expect(failing.prices[CryptoCurrency.xmr], 300);
  });

  test("a failed new-fiat fetch cannot restore the previous-fiat price", () async {
    await load(CryptoCurrency.xmr, 300);
    runInAction(() => fiat.value = FiatCurrency.uah);
    final refreshed = store.fetchPrice(CryptoCurrency.xmr);
    requests.last.result.complete(0);
    await refreshed;
    expect(store.prices[CryptoCurrency.xmr], isNull);
    await load(CryptoCurrency.xmr, 12000);
    expect(store.prices[CryptoCurrency.xmr], 12000);
  });

  test("disabled fiat blocks requests and rejects an outstanding response", () async {
    final old = store.fetchPrice(CryptoCurrency.xmr);
    runInAction(() => mode.value = FiatApiMode.disabled);
    await store.fetchPrice(CryptoCurrency.eth);
    requests.single.result.complete(300);
    await old;
    expect(store.prices, isEmpty);
    expect(requests.length, 1);
    runInAction(() => fiat.value = FiatCurrency.uah);
    expect(requests.length, 1);
    runInAction(() => mode.value = FiatApiMode.torOnly);
    expect(requests.length, 3);
    expect(requests.skip(1).every((request) => request.torOnly), true);
    expect(requests.skip(1).every((request) => request.fiat == FiatCurrency.uah), true);
  });

  test("switching to Tor-only invalidates clearnet work", () async {
    final old = store.fetchPrice(CryptoCurrency.xmr);
    runInAction(() => mode.value = FiatApiMode.torOnly);
    final current = store.fetchPrice(CryptoCurrency.xmr);
    expect(requests.last.torOnly, true);
    requests.last.result.complete(310);
    await current;
    requests.first.result.complete(300);
    await old;
    expect(store.prices[CryptoCurrency.xmr], 310);
  });

  test("fetch inside the action changing fiat cannot reuse the old cache", () async {
    await load(CryptoCurrency.xmr, 300);
    late Future<void> changed;
    runInAction(() {
      fiat.value = FiatCurrency.uah;
      changed = store.fetchPrice(CryptoCurrency.xmr);
    });
    expect(requests.last.fiat, FiatCurrency.uah);
    requests.last.result.complete(12000);
    await changed;
    expect(store.prices[CryptoCurrency.xmr], 12000);
  });

  test("disposing stops reactions and rejects pending responses", () async {
    final pending = store.fetchPrice(CryptoCurrency.xmr);
    store.dispose();
    runInAction(() => fiat.value = FiatCurrency.uah);
    requests.single.result.complete(300);
    await pending;
    await store.fetchPrice(CryptoCurrency.eth);
    expect(store.prices, isEmpty);
    expect(requests.length, 1);
  });
}

import "package:cake_wallet/entities/balance_display_mode.dart";
import "package:cake_wallet/entities/bitcoin_amount_display_mode.dart";
import "package:cake_wallet/new-ui/widgets/money/money_settings_cubit.dart";
import "package:cake_wallet/new-ui/widgets/money/use_base_unit_provider.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/currency.dart";
import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:flutter_test/flutter_test.dart";

class FakeMoneySettingsCubit extends Cubit<MoneySettingsState> implements MoneySettingsCubit {
  FakeMoneySettingsCubit(super.initialState);

  void setState(MoneySettingsState state) => emit(state);
}

MoneySettingsState _moneySettingsState({
  BitcoinAmountDisplayMode bitcoin = BitcoinAmountDisplayMode.bitcoin,
  BalanceDisplayMode display = BalanceDisplayMode.availableBalance,
}) =>
    MoneySettingsState(
      bitcoinAmountDisplayMode: bitcoin,
      displayMode: display,
    );

Future<void> _pumpEmission(WidgetTester tester) => tester.pump(Duration.zero);

/// Leaf that depends on [BaseUnitConfig] for one or more currencies and appends the
/// values it observed to [log] on every build.
///
/// One entry per build, so `log.length` is a build count and `log.last` holds
/// the most recently observed values.
class _Probe extends StatelessWidget {
  const _Probe({required this.currencies, required this.log});

  _Probe.single(Currency currency, {required this.log, super.key})
      : currencies = <Currency>[currency];

  final List<Currency> currencies;
  final List<List<bool>> log;

  @override
  Widget build(BuildContext context) {
    final observed =
        currencies.map((c) => BaseUnit.useBaseUnitOf(context, c)).toList(growable: false);
    log.add(observed);
    return const SizedBox.shrink();
  }
}

/// Wires [child] under a real [BlocBuilder] so state changes flow through the
/// same path as production code.
///
/// [child] is captured by the builder closure rather than constructed inside
/// it. That is load-bearing: an identical widget instance makes
/// `Element.updateChild` short-circuit, so the only thing that can rebuild the
/// probe is [InheritedModel] aspect notification.
///
/// [builderLog] records every [BlocBuilder] invocation. Assert on it in any
/// test that expects a probe *not* to rebuild — otherwise a test that stops
/// receiving emissions at all will pass for the wrong reason.
Widget _host(FakeMoneySettingsCubit cubit, Widget child) => MaterialApp(
      home: BlocProvider<MoneySettingsCubit>.value(
        value: cubit,
        child: BaseUnitScope(
          child: child,
        ),
      ),
    );

void main() {
  // ---------------------------------------------------------------------------
  // Reading through the model.
  // ---------------------------------------------------------------------------
  group("BaseUnitConfig.useBaseUnitOf", () {
    testWidgets("reads the value from the nearest ancestor", (tester) async {
      final cubit = FakeMoneySettingsCubit(
        _moneySettingsState(bitcoin: BitcoinAmountDisplayMode.satoshi),
      );
      final log = <List<bool>>[];

      await tester.pumpWidget(
        _host(cubit, _Probe.single(CryptoCurrency.btc, log: log)),
      );

      expect(
        log,
        [
          [true]
        ],
      );
    });

    testWidgets("nearest ancestor wins when models are nested", (tester) async {
      final log = <List<bool>>[];

      await tester.pumpWidget(
        BaseUnit(
          state: _moneySettingsState(bitcoin: BitcoinAmountDisplayMode.satoshi),
          child: BaseUnit(
            state: _moneySettingsState(bitcoin: BitcoinAmountDisplayMode.bitcoin),
            child: _Probe.single(CryptoCurrency.btc, log: log),
          ),
        ),
      );

      expect(log.single, [false]);
    });

    testWidgets("throws when no BaseUnitConfig ancestor exists", (tester) async {
      await tester.pumpWidget(
        _Probe.single(CryptoCurrency.btc, log: <List<bool>>[]),
      );

      // `inheritFrom` returns null and the `!` in useBaseUnitOf blows up. This
      // pins current behaviour; swapping the `!` for an assert with a readable
      // message would make this a much friendlier failure.
      expect(tester.takeException(), isA<TypeError>());
    });
  });

  // ---------------------------------------------------------------------------
  // Aspect notification. This is the whole reason for the InheritedModel.
  // ---------------------------------------------------------------------------
  group("BaseUnitConfig aspect notification", () {
    testWidgets("rebuilds a dependent whose currency flipped", (tester) async {
      final cubit = FakeMoneySettingsCubit(
        _moneySettingsState(bitcoin: BitcoinAmountDisplayMode.bitcoin),
      );
      final log = <List<bool>>[];

      await tester.pumpWidget(
        _host(
          cubit,
          _Probe.single(CryptoCurrency.btc, log: log),
        ),
      );
      expect(log.length, 1);

      cubit.setState(_moneySettingsState(bitcoin: BitcoinAmountDisplayMode.satoshi));
      await _pumpEmission(tester);

      expect(log.length, 2);
      expect(log.last, [true]);
    });

    testWidgets("satoshi -> satoshiForLightning rebuilds btc but not btcln", (tester) async {
      final cubit = FakeMoneySettingsCubit(
        _moneySettingsState(bitcoin: BitcoinAmountDisplayMode.satoshi),
      );
      final btcLog = <List<bool>>[];
      final btclnLog = <List<bool>>[];

      await tester.pumpWidget(
        _host(
          cubit,
          Row(
            children: [
              _Probe.single(
                CryptoCurrency.btc,
                log: btcLog,
                key: const ValueKey("btc"),
              ),
              _Probe.single(CryptoCurrency.btcln, log: btclnLog, key: const ValueKey("btcln")),
            ],
          ),
        ),
      );
      expect(btcLog.single, [true]);
      expect(btclnLog.single, [true]);

      cubit.setState(
        _moneySettingsState(bitcoin: BitcoinAmountDisplayMode.satoshiForLightning),
      );
      await _pumpEmission(tester);

      // btc: true -> false, so it must rebuild.
      expect(btcLog.length, 2);
      expect(btcLog.last, [false]);

      // btcln: true -> true. The aspect filter should have spared it.
      expect(btclnLog.length, 1, reason: "btcln value did not change");
    });

    testWidgets("a currency outside the bitcoin family never rebuilds", (tester) async {
      final cubit = FakeMoneySettingsCubit(
        _moneySettingsState(bitcoin: BitcoinAmountDisplayMode.bitcoin),
      );
      final log = <List<bool>>[];

      await tester.pumpWidget(
        _host(
          cubit,
          _Probe.single(CryptoCurrency.xmr, log: log),
        ),
      );

      for (final mode in BitcoinAmountDisplayMode.all) {
        cubit.setState(_moneySettingsState(bitcoin: mode));
        await _pumpEmission(tester);
      }

      expect(log.length, 1);
    });

    testWidgets("a dependent on several currencies rebuilds if any changed", (tester) async {
      final cubit = FakeMoneySettingsCubit(
        _moneySettingsState(bitcoin: BitcoinAmountDisplayMode.satoshi),
      );
      final log = <List<bool>>[];

      await tester.pumpWidget(
        _host(
          cubit,
          _Probe(
            currencies: <Currency>[CryptoCurrency.xmr, CryptoCurrency.btc],
            log: log,
          ),
        ),
      );
      expect(log.single, [false, true]);

      // Only btc changes, but the element depends on both aspects.
      cubit.setState(
        _moneySettingsState(bitcoin: BitcoinAmountDisplayMode.satoshiForLightning),
      );
      await _pumpEmission(tester);

      expect(log.length, 2);
      expect(log.last, [false, false]);
    });

    testWidgets("a value-equal but distinct state does not reach dependents", (tester) async {
      final initial = _moneySettingsState(bitcoin: BitcoinAmountDisplayMode.satoshi);
      final cubit = FakeMoneySettingsCubit(initial);
      final log = <List<bool>>[];

      await tester.pumpWidget(
        _host(
          cubit,
          _Probe.single(CryptoCurrency.btc, log: log),
        ),
      );
      expect(log.length, 1);

      // MoneySettingsState has no `==`, so this emits and updateShouldNotify
      // returns true on identity. updateShouldNotifyDependent is the only thing
      // stopping a spurious dependent rebuild here.
      cubit.setState(initial.copyWith());
      await _pumpEmission(tester);

      expect(log.length, 1);
    });

    testWidgets("changing only displayMode does not reach useBaseUnit dependents", (tester) async {
      final cubit = FakeMoneySettingsCubit(
        _moneySettingsState(
          bitcoin: BitcoinAmountDisplayMode.satoshi,
          display: BalanceDisplayMode.availableBalance,
        ),
      );
      final log = <List<bool>>[];

      await tester.pumpWidget(
        _host(
          cubit,
          _Probe.single(CryptoCurrency.btc, log: log),
        ),
      );

      cubit.setState(
        _moneySettingsState(
          bitcoin: BitcoinAmountDisplayMode.satoshi,
          display: BalanceDisplayMode.hiddenBalance,
        ),
      );
      await _pumpEmission(tester);

      // Correct for useBaseUnit dependents, and a trap for any future
      // isHiddenOf/getSymbolOf accessor: updateShouldNotifyDependent compares
      // useBaseUnit only, so a displayMode-only change would be swallowed.
      expect(log.length, 1);
    });
  });
}

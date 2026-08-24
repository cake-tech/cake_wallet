import "dart:async";

import "package:cake_wallet/new-ui/widgets/money/money_settings_cubit.dart";
import "package:cw_core/currency.dart";
import "package:flutter/widgets.dart";
import "package:flutter_bloc/flutter_bloc.dart";

/// Read-only view of the money display settings for the current subtree.
///
/// ```dart
/// final useBaseUnit = BaseUnitConfig.useBaseUnitOf(context, CryptoCurrency.btc);
/// ```
class BaseUnit extends InheritedModel<Currency> {
  const BaseUnit({required this.state, required super.child});

  final MoneySettingsState state;

  static bool useBaseUnitOf(BuildContext context, Currency currency) =>
      InheritedModel.inheritFrom<BaseUnit>(context, aspect: currency)!.state.useBaseUnit(currency);

  static String getSymbolOf(BuildContext context, Currency currency) =>
      InheritedModel.inheritFrom<BaseUnit>(context, aspect: currency)!.state.getSymbol(currency);

  @override
  bool updateShouldNotify(BaseUnit old) => state != old.state;

  @override
  bool updateShouldNotifyDependent(BaseUnit old, Set<Currency> aspects) => aspects.any((c) =>
      state.useBaseUnit(c) != old.state.useBaseUnit(c) ||
      state.getSymbol(c) != old.state.getSymbol(c));
}

class BaseUnitScope extends StatefulWidget {
  const BaseUnitScope({required this.child, super.key});

  final Widget child;

  @override
  State<BaseUnitScope> createState() => _BaseUnitScopeState();
}

class _BaseUnitScopeState extends State<BaseUnitScope> {
  late MoneySettingsState _state;
  late final StreamSubscription<MoneySettingsState> _sub;

  @override
  void initState() {
    super.initState();
    final cubit = context.read<MoneySettingsCubit>();
    _state = cubit.state;
    _sub = cubit.stream.listen((s) => setState(() => _state = s));
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => BaseUnit(state: _state, child: widget.child);
}

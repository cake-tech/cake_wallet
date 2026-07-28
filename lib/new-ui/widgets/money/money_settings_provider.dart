import "package:cake_wallet/new-ui/widgets/money/money_settings_cubit.dart";
import "package:cake_wallet/store/settings_store.dart";
import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";

class MoneySettingsProvider extends StatelessWidget {
  const MoneySettingsProvider({required this.settingsStore, this.child, super.key});

  final Widget? child;
  final SettingsStore settingsStore;

  @override
  Widget build(BuildContext context) =>
      BlocProvider(create: (_) => MoneySettingsCubit(settingsStore), child: child);
}

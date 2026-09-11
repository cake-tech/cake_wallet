import 'package:cake_wallet/di.dart';
import 'package:cake_wallet/new-ui/modal_navigator.dart';
import 'package:cake_wallet/new-ui/pages/card_customizer.dart';
import 'package:cake_wallet/new-ui/viewmodels/card_customizer/card_customizer_bloc.dart';
import 'package:cake_wallet/view_model/dashboard/dashboard_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

Future<void> showCardCustomizer({
  required BuildContext context,
  required DashboardViewModel dashboardViewModel,
  required bool lightningMode,
  bool useCupertinoScaffold = true,
  VoidCallback? onSaved,
}) async {
  final bloc = getIt.get<CardCustomizerBloc>(
    param1: lightningMode,
    param2: dashboardViewModel.settingsStore.displayAmountsInSatoshi,
  );

  Widget buildCustomizer(BuildContext context) => ModalNavigator(
      parentContext: context,
      heightMode: ModalHeightModes.fullScreen,
      rootPage: BlocProvider(
        create: (context) => bloc,
        child: Material(
          child: CardCustomizer(
            cryptoTitle: dashboardViewModel.wallet.currency.fullName ??
                dashboardViewModel.wallet.currency.name,
            cryptoName: dashboardViewModel.wallet.currency.name,
          ),
        ),
      ),
    );

  if (useCupertinoScaffold) {
    await CupertinoScaffold.showCupertinoModalBottomSheet(
      barrierColor: Colors.black.withAlpha(60),
      context: context,
      builder: buildCustomizer,
    );
  } else {
    await showCupertinoModalBottomSheet(
      barrierColor: Colors.black.withAlpha(60),
      context: context,
      builder: buildCustomizer,
    );
  }

  bloc.add(DesignSaved());
  await bloc.stream.firstWhere((s) => s is CardCustomizerSaved);
  await dashboardViewModel.loadCardDesigns();
  await dashboardViewModel.accountListViewModel?.reload();

  onSaved?.call();
}

import "package:cake_wallet/di.dart";
import "package:cake_wallet/new-ui/modal_navigator.dart";
import "package:cake_wallet/new-ui/pages/card_customizer.dart";
import "package:cake_wallet/new-ui/viewmodels/card_customizer/card_customizer_bloc.dart";
import "package:cake_wallet/view_model/dashboard/dashboard_view_model.dart";
import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:modal_bottom_sheet/modal_bottom_sheet.dart";

Future<void> showCardCustomizer({
  required BuildContext context,
  required DashboardViewModel dashboardViewModel,
  required bool lightningMode,
  bool asModalSheet = true,
  VoidCallback? onSaved,
}) async {
  final bloc = getIt.get<CardCustomizerBloc>(
    param1: lightningMode,
    param2: dashboardViewModel.settingsStore.displayAmountsInSatoshi,
  );

  final customizer = BlocProvider(
    create: (_) => bloc,
    child: Material(
      child: CardCustomizer(
        cryptoTitle:
            dashboardViewModel.wallet.currency.fullName ?? dashboardViewModel.wallet.currency.name,
        cryptoName: dashboardViewModel.wallet.currency.name,
      ),
    ),
  );

  if (asModalSheet) {
    await CupertinoScaffold.showCupertinoModalBottomSheet(
      barrierColor: Colors.black.withAlpha(60),
      context: context,
      builder: (context) => ModalNavigator(
        parentContext: context,
        heightMode: ModalHeightModes.fullScreen,
        rootPage: customizer,
      ),
    );
  } else {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => customizer),
    );
  }

  bloc.add(DesignSaved());

  await bloc.stream.firstWhere(
    (state) => state is CardCustomizerSaved,
    orElse: () => bloc.state,
  );

  await dashboardViewModel.loadCardDesigns();
  await dashboardViewModel.accountListViewModel?.reload();

  onSaved?.call();
}

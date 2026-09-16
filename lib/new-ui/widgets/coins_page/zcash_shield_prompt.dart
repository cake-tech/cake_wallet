import 'package:cake_wallet/di.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/main.dart';
import 'package:cake_wallet/new-ui/widgets/coins_page/zcash_shield_sent_sheet.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/connect_device/connect_device_page.dart';
import 'package:cake_wallet/src/widgets/alert_with_one_action.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:cake_wallet/view_model/dashboard/dashboard_view_model.dart';
import 'package:cake_wallet/view_model/hardware_wallet/hardware_wallet_view_model.dart';
import 'package:cake_wallet/zcash/zcash.dart';
import 'package:cake_wallet/new-ui/widgets/hardware_wallet/proceed_on_device_message.dart';
import 'package:cw_core/hardware/hardware_signing_stage.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

/// Offers to sweep transparent funds a hardware Zcash wallet cannot sweep
/// itself.
///
/// Shielding normally runs unattended during sync, which needs a local
/// spending key. A Ledger wallet has none: the sweep is built here, reviewed
/// and signed on the device, then broadcast, all from one tap on this card.
/// Without it the funds would sit unspendable, since ordinary sends draw from
/// the shielded pools only.
class ZcashShieldPrompt extends StatelessWidget {
  const ZcashShieldPrompt({super.key, required this.dashboardViewModel});

  final DashboardViewModel dashboardViewModel;

  /// Makes sure the device is connected and attached to the wallet, prompting
  /// for a connection the same way the send screen does.
  Future<bool> _ensureDevice(BuildContext context) async {
    final wallet = dashboardViewModel.wallet;
    final hardwareType = wallet.walletInfo.hardwareWalletType;
    if (hardwareType == null) {
      return true;
    }
    final hwVM = getIt.get<HardwareWalletViewModel>(param1: hardwareType);
    if (!hwVM.isConnected(WalletType.zcash)) {
      await Navigator.of(context).pushNamed(
        Routes.connectDevices,
        arguments: ConnectDevicePageParams(
          walletType: WalletType.zcash,
          hardwareWalletType: hardwareType,
          onConnectDevice: (_, __) {
            hwVM.initWallet(wallet);
            Navigator.of(context).pop();
          },
          isReconnect: false,
        ),
      );
      // Recheck to handle a tap-back from the connect page.
      if (!hwVM.isConnected(WalletType.zcash)) {
        return false;
      }
    } else {
      await hwVM.initWallet(wallet);
    }
    return true;
  }

  Future<void> _shield(BuildContext context) async {
    if (!await _ensureDevice(context)) {
      return;
    }
    if (!context.mounted) return;

    // The device review happens while the sweep is prepared; keep a notice
    // up until that returns. It says what is being waited on: the device only
    // shows its review once the whole sweep has reached it.
    var noticeOpen = true;
    final stage = ValueNotifier<HardwareSigningStage?>(HardwareSigningStage.preparing);
    final stages = zcash!
        .ledgerSigningStages(dashboardViewModel.wallet)
        .listen((s) => stage.value = s);
    // ignore: unawaited_futures
    showPopUp<void>(
      context: context,
      builder: (BuildContext ctx) => ValueListenableBuilder<HardwareSigningStage?>(
        valueListenable: stage,
        builder: (ctx, current, _) => AlertWithOneAction(
          alertTitle: HardwareWalletProceedOnDeviceMessage.textFor(ctx, current),
          alertContent: current == HardwareSigningStage.awaitingDevice
              ? S.of(ctx).proceed_on_device_description
              : S.of(ctx).please_wait,
          buttonText: S.of(ctx).cancel,
          alertBarrierDismissible: false,
          buttonAction: () {
            noticeOpen = false;
            Navigator.of(ctx).pop();
          },
        ),
      ),
    );
    void closeNotice() {
      stages.cancel();
      if (noticeOpen && context.mounted) {
        noticeOpen = false;
        Navigator.of(context).pop();
      }
    }

    try {
      final pending = await zcash!.createShieldTransaction(dashboardViewModel.wallet);
      await pending.commit();
      closeNotice();
      // The funds are being shielded now: hide the card, then show the
      // "Transaction sent" cake. A send swaps its own sheet for the cake; the
      // shield has no such sheet, so show one over the dashboard.
      dashboardViewModel.markZcashShielded();
      final navCtx = navigatorKey.currentContext;
      if (navCtx != null) {
        await showModalBottomSheet<void>(
          context: navCtx,
          isScrollControlled: true,
          isDismissible: false,
          enableDrag: false,
          backgroundColor: Colors.transparent,
          builder: (sheetCtx) => ZcashShieldSentSheet(onDone: () => Navigator.of(sheetCtx).pop()),
        );
      }
    } catch (e) {
      closeNotice();
      if (!context.mounted) return;
      await showPopUp<void>(
        context: context,
        builder: (BuildContext ctx) => AlertWithOneAction(
          alertTitle: S.of(ctx).error,
          alertContent: e.toString(),
          buttonText: S.of(ctx).ok,
          buttonAction: () => Navigator.of(ctx).pop(),
        ),
      );
      await dashboardViewModel.refreshZcashShieldable();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Observer(builder: (_) {
      if (!dashboardViewModel.showZcashShieldCard) return const SizedBox.shrink();

      return Padding(
        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12, top: 24),
        child: MergeSemantics(
          child: Semantics(
            button: true,
            child: GestureDetector(
              onTap: () => _shield(context),
              child: Container(
                height: 64,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: Theme.of(context).colorScheme.surfaceContainer,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ExcludeSemantics(
                        child: Icon(
                          Icons.shield_outlined,
                          size: 24,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12.0),
                          child: Text(
                            S.of(context).zcash_shield_transparent_funds_ledger,
                            softWrap: true,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                      Icon(
                        size: 16,
                        Icons.arrow_forward_ios,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    });
  }
}

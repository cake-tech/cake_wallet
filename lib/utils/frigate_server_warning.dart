import 'package:cake_wallet/bitcoin/bitcoin.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/widgets/alert_with_two_actions.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:flutter/material.dart';

Future<bool> showFrigateElectrumServerWarning({
  required BuildContext context,
  required WalletBase wallet,
}) async {
  if (wallet.type != WalletType.bitcoin || bitcoin == null) {
    return true;
  }

  final isFrigate = await bitcoin!.getNodeIsFrigate(wallet);

  if (!isFrigate) {
    return true;
  }

  var shouldProceed = false;

  await showPopUp<void>(
    context: context,
    builder: (dialogContext) => AlertWithTwoActions(
      alertTitle: S.of(dialogContext).alert_notice,
      alertContent: S.of(dialogContext).frigate_electrum_server_warning,
      rightButtonText: S.of(dialogContext).confirm,
      leftButtonText: S.of(dialogContext).cancel,
      actionRightButton: () {
        shouldProceed = true;
        Navigator.of(dialogContext).pop();
      },
      actionLeftButton: () => Navigator.of(dialogContext).pop(),
    ),
  );

  return shouldProceed;
}

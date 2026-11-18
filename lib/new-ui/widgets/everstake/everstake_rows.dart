import "package:cake_wallet/entities/new_ui_entities/list_item/list_item_regular_row.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/widgets/defi/defi_rows.dart";
import "package:flutter/material.dart";

ListItemRegularRow everstakeProviderRow(BuildContext context) =>
    defiProviderRow(context, name: "Everstake", website: Uri.https("everstake.com"));

ListItemRegularRow everstakeServiceFeeRow(BuildContext context, double poolFee) => defiTextRow(
      context,
      keyValue: "staking_service_fee",
      label: S.of(context).service_fee,
      value: S.of(context).percent_of_rewards(defiPercentText(context, poolFee)),
    );

String everstakeAprText(BuildContext context, double apr) =>
    S.of(context).percent_apr(defiPercentText(context, apr));

ListItemRegularRow everstakeYieldRow(
  BuildContext context,
  double apr, {
  bool approximate = false,
}) =>
    defiYieldRow(context, everstakeAprText(context, apr), approximate: approximate);

ListItemRegularRow everstakeActivationRow(BuildContext context, Duration activationTime) =>
    defiTextRow(
      context,
      keyValue: "staking_activation",
      label: S.of(context).stake_activation,
      value: _approximateDuration(context, activationTime),
    );

ListItemRegularRow everstakeWithdrawalTimeRow(BuildContext context, Duration withdrawalTime) =>
    defiTextRow(
      context,
      keyValue: "staking_withdrawal_time",
      label: S.of(context).withdrawal_time,
      value: _approximateDuration(context, withdrawalTime),
    );

String _approximateDuration(BuildContext context, Duration duration) {
  final hours = duration.inHours;
  return "~${S.of(context).duration_days_hours("${hours ~/ 24}", "${hours % 24}")}";
}

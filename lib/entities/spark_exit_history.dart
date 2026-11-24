import "package:cake_wallet/generated/i18n.dart";

/// How a unilateral exit step reads in the history, from the `additionalInfo` tags the wallet
/// puts on it (`UnilateralExitHistoryEntry` in cw_bitcoin writes the same names).
class SparkExitHistory {
  static bool isSparkExit(Map<String, dynamic> additionalInfo) =>
      additionalInfo["isSparkExit"] == true;

  static String? titleFor(Map<String, dynamic> additionalInfo) {
    if (!isSparkExit(additionalInfo)) {
      return null;
    }

    final step = "${additionalInfo["sparkExitStepNumber"]}";
    final total = "${additionalInfo["sparkExitStepCount"]}";

    final title = switch (additionalInfo["sparkExitStep"]) {
      "cooperative" => S.current.spark_exit_step_cooperative(step, total),
      "fanOut" => S.current.spark_exit_step_fan_out,
      "node" => S.current.spark_exit_step_node(step, total),
      "refund" => S.current.spark_exit_step_refund(step, total),
      "fee" => S.current.spark_exit_step_fee(step, total),
      _ => S.current.spark_exit_step_sweep(step, total),
    };

    return switch (additionalInfo["sparkExitState"]) {
      "waiting" => "$title (${S.current.spark_exit_state_waiting})",
      "waitingForBlock" => "$title (${S.current.spark_exit_state_waiting_block(
          "${additionalInfo["sparkExitSpendableAtHeight"]}",
        )})",
      "checking" => "$title (${S.current.spark_exit_state_checking})",
      "stalled" => "$title (${S.current.spark_exit_state_stalled})",
      "rebuild" => "$title (${S.current.spark_exit_state_rebuild})",
      _ => title,
    };
  }

  static String explanationFor(Map<String, dynamic> additionalInfo) =>
      switch (additionalInfo["sparkExitStep"]) {
        "cooperative" => S.current.spark_exit_explain_cooperative,
        "fanOut" => S.current.spark_exit_explain_fan_out,
        "node" => S.current.spark_exit_explain_node,
        "refund" => S.current.spark_exit_explain_refund(
            "${additionalInfo["sparkExitTimelockBlocks"]}",
          ),
        "fee" => S.current.spark_exit_explain_fee("${additionalInfo["sparkExitStepNumber"]}"),
        _ => S.current.spark_exit_explain_sweep,
      };
}

import "package:cake_wallet/new-ui/pages/wallet_network/network_details_page.dart";
import "package:cake_wallet/new-ui/viewmodels/wallet_network/network_details_bloc.dart";
import "package:cake_wallet/new-ui/widgets/new_primary_button.dart";
import "package:cake_wallet/src/widgets/alert_with_two_actions.dart";
import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";

import "../core/base_robot.dart";

class NetworkDetailsPageRobot extends BaseRobot {
  NetworkDetailsPageRobot(super.tester);

  @override
  Future<void> isDisplayed() async {
    await isSpecificPage<NetworkDetailsPage>();

    // Save stays disabled until the wallet and contact counts load
    final loaded = await pumpUntil(() => !_button("network_details_save_button_key").disabled);

    expect(loaded, true, reason: "The network form never finished loading its usage counts");
  }

  bool get isShowing => tester.any(find.byType(NetworkDetailsPage));

  Finder _fieldBox(NetworkField field) =>
      find.byKey(ValueKey("network_details_${field.name}_field_key"));

  Finder _editableField(NetworkField field) =>
      find.descendant(of: _fieldBox(field), matching: find.byType(EditableText));

  NewPrimaryButton _button(String key) =>
      tester.widget<NewPrimaryButton>(find.byKey(ValueKey(key)));

  Future<void> revealFailover() async {
    await tapByKey("network_details_reveal_failover_button_key");

    await pumpUntilFound(_fieldBox(NetworkField.failoverUrl));
  }

  Future<void> enterField(NetworkField field, String value) async {
    await pumpUntilFound(_editableField(field));

    await tester.enterText(_editableField(field).first, value);
    await tester.pump(const Duration(milliseconds: 200));
  }

  Future<void> fillForm({
    required String name,
    required String rpcUrl,
    required String chainId,
    required String symbol,
    String explorerUrl = "",
  }) async {
    await enterField(NetworkField.name, name);
    await enterField(NetworkField.rpcUrl, rpcUrl);
    await enterField(NetworkField.chainId, chainId);
    await enterField(NetworkField.symbol, symbol);
    await enterField(NetworkField.explorerUrl, explorerUrl);
  }

  bool isReadOnly(NetworkField field) =>
      tester.any(_fieldBox(field)) && !tester.any(_editableField(field));

  String getFieldValue(NetworkField field) {
    if (tester.any(_editableField(field))) {
      return tester.widget<EditableText>(_editableField(field).first).controller.text;
    }

    final text = find.descendant(of: _fieldBox(field), matching: find.byType(Text));

    return tester.widget<Text>(text.first).data ?? "";
  }

  Future<void> tapResetToDefault() async {
    await tapByKey("network_details_reset_button_key");
  }

  String? fieldError(NetworkField field) => textByKey("network_details_${field.name}_error_key");

  Future<void> tapSave() async {
    await tapByKey("network_details_save_button_key");
  }

  /// Taps Save and waits for either the page to close or an error under any field
  Future<void> saveExpectingError(NetworkField field, {Duration? timeout}) async {
    await tapSave();

    // A save that reaches the RPC check waits up to 10 s per URL
    final shown = await pumpUntil(
      () => fieldError(field) != null || !isShowing,
      timeout: timeout ?? const Duration(seconds: 45),
    );

    expect(shown, true, reason: "No ${field.name} error appeared after Save");
    expect(isShowing, true, reason: "Save closed the form instead of refusing ${field.name}");
  }

  Future<void> saveExpectingClose() async {
    await tapSave();

    final closed = await pumpUntil(() => !isShowing, timeout: const Duration(seconds: 45));

    if (!closed) {
      final errors = NetworkField.values
          .map((field) => "${field.name}: ${fieldError(field)}")
          .where((line) => !line.endsWith("null"))
          .join(", ");

      throw TestFailure("Save did not close the form. Field errors: $errors");
    }
  }

  bool get hasNodesManagedNote => isKeyPresent("network_details_nodes_managed_text_key");

  bool get isDeleteShown => isKeyPresent("network_details_delete_button_key");

  bool get isDeleteEnabled => !_button("network_details_delete_button_key").disabled;

  String? get deleteRefusedText => textByKey("network_details_delete_refused_text_key");

  Future<void> tapDelete() async {
    await tapByKey("network_details_delete_button_key");

    await pumpUntilFound(find.byType(AlertWithTwoActions));
  }

  String deleteWarningMessage() =>
      tester.widget<AlertWithTwoActions>(find.byType(AlertWithTwoActions)).alertContent;

  Future<void> cancelDelete() async {
    await tapByKey("network_details_delete_cancel_button_key");

    await pumpUntilGone(find.byType(AlertWithTwoActions));
  }

  Future<void> confirmDelete() async {
    await tapByKey("network_details_delete_continue_button_key");

    final closed = await pumpUntil(() => !isShowing);

    expect(closed, true, reason: "Continue on the delete warning did not close the form");
  }

  Future<void> closeForm() async {
    await tapWhenVisible(
      find.descendant(
        of: find.byType(NetworkDetailsPage),
        matching: find.byIcon(Icons.arrow_back_ios_new),
      ),
    );

    await pumpUntilGone(find.byType(NetworkDetailsPage));
  }
}

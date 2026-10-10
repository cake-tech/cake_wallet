import "package:cake_wallet/di.dart";
import "package:cake_wallet/entities/new_ui_entities/list_item/list_item_regular_row.dart";
import "package:cake_wallet/entities/new_ui_entities/list_item/list_item_toggle.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/locales/locale.dart";
import "package:cake_wallet/new-ui/widgets/line_tab_switcher.dart";
import "package:cake_wallet/new-ui/widgets/modern_button.dart";
import "package:cake_wallet/new-ui/widgets/new_primary_button.dart";
import "package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart";
import "package:cake_wallet/new-ui/widgets/stacked_buttons.dart";
import "package:cake_wallet/src/screens/settings/widgets/settings_cell_with_arrow.dart";
import "package:cake_wallet/src/screens/settings/widgets/settings_switcher_cell.dart";
import "package:cake_wallet/src/widgets/alert_with_one_action.dart";
import "package:cake_wallet/src/widgets/alert_with_two_actions.dart";
import "package:cake_wallet/src/widgets/base_text_form_field.dart";
import "package:cake_wallet/src/widgets/new_list_row/list_item_toggle_widget.dart";
import "package:cake_wallet/src/widgets/new_list_row/new_list_section.dart";
import "package:cake_wallet/src/widgets/primary_button.dart";
import "package:cake_wallet/themes/core/theme_store.dart";
import "package:flutter/material.dart";
import "package:flutter/semantics.dart";
import "package:flutter_test/flutter_test.dart";

import "../../utils/semantics_helpers.dart";

void main() {
  late bool registeredThemeStore;

  setUpAll(() {
    registeredThemeStore = !getIt.isRegistered<ThemeStore>();
    if (registeredThemeStore) {
      getIt.registerSingleton(ThemeStore());
    }
  });

  tearDownAll(() async {
    if (registeredThemeStore) {
      await getIt.unregister<ThemeStore>();
    }
  });

  Widget wrap(Widget child) => MaterialApp(
        localizationsDelegates: localizationDelegates,
        supportedLocales: S.delegate.supportedLocales,
        home: Scaffold(body: Center(child: child)),
      );

  Future<SemanticsNode> pumpAndFindOne(WidgetTester tester, Widget widget, String id) async {
    await tester.pumpWidget(wrap(widget));
    await tester.pumpAndSettle();
    final nodes = platformNodesWithId(tester, id);
    expect(nodes, hasLength(1), reason: "exactly one platform node should carry '$id'");
    expect(find.bySemanticsIdentifier(id), findsOneWidget);
    return nodes.single;
  }

  group("ModernButton", () {
    testWidgets("a test key becomes the identifier of its one button node", (tester) async {
      final handle = tester.ensureSemantics();
      final node = await pumpAndFindOne(
        tester,
        ModernButton(
          key: const ValueKey("x_button_key"),
          size: 40,
          icon: const Icon(Icons.close),
          onPressed: () {},
          semanticLabel: "Close",
        ),
        "x_button_key",
      );

      expect(
        node,
        isSemantics(identifier: "x_button_key", label: "Close", isButton: true, hasTapAction: true),
      );
      expect(find.byKey(const ValueKey("x_button_key")), findsOneWidget);
      handle.dispose();
    });

    testWidgets("an explicit testId wins over the key", (tester) async {
      final handle = tester.ensureSemantics();
      await pumpAndFindOne(
        tester,
        ModernButton(
          key: const ValueKey("x_button_key"),
          testId: "explicit_button_key",
          size: 40,
          icon: const Icon(Icons.close),
          onPressed: () {},
          label: "Close",
        ),
        "explicit_button_key",
      );
      expect(find.bySemanticsIdentifier("x_button_key"), findsNothing);
      handle.dispose();
    });

    testWidgets("a non-test key does not become an identifier", (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        wrap(
          ModernButton(
            key: const ValueKey("Satoshi's wallet"),
            size: 40,
            icon: const Icon(Icons.close),
            onPressed: () {},
            label: "Close",
          ),
        ),
      );
      expect(find.bySemanticsIdentifier(RegExp(".")), findsNothing);
      handle.dispose();
    });
  });

  group("ModalTopBar", () {
    testWidgets("title is its own header node and chrome buttons get stable ids", (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        wrap(
          ModalTopBar(
            testId: "receive_amount_modal",
            title: "Set amount",
            leadingIcon: const Icon(Icons.arrow_back),
            leadingSemanticLabel: "Back",
            trailingIcon: const Icon(Icons.close),
            trailingSemanticLabel: "Close",
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        platformNodesWithId(tester, "receive_amount_modal_title_key").single,
        isSemantics(label: "Set amount", isHeader: true),
      );
      expect(
        platformNodesWithId(tester, "receive_amount_modal_leading_key").single,
        isSemantics(label: "Back", isButton: true),
      );
      expect(
        platformNodesWithId(tester, "receive_amount_modal_trailing_key").single,
        isSemantics(label: "Close", isButton: true),
      );
      handle.dispose();
    });

    testWidgets("falls back to modal_top_bar ids", (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(wrap(ModalTopBar(title: "Receive")));
      await tester.pumpAndSettle();
      expect(platformNodesWithId(tester, "modal_top_bar_title_key"), hasLength(1));
      handle.dispose();
    });
  });

  group("primary buttons", () {
    testWidgets("NewPrimaryButton", (tester) async {
      final handle = tester.ensureSemantics();
      final node = await pumpAndFindOne(
        tester,
        NewPrimaryButton(
          key: const ValueKey("new_wallet_continue_button_key"),
          onPressed: () {},
          text: "Continue",
          color: Colors.blue,
          textColor: Colors.white,
        ),
        "new_wallet_continue_button_key",
      );
      expect(node, isSemantics(label: "Continue", isButton: true, hasTapAction: true));
      handle.dispose();
    });

    testWidgets("PrimaryButton and LoadingPrimaryButton", (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        wrap(
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              PrimaryButton(
                key: const ValueKey("primary_button_key"),
                onPressed: () {},
                text: "Next",
                color: Colors.blue,
                textColor: Colors.white,
              ),
              LoadingPrimaryButton(
                key: const ValueKey("loading_primary_button_key"),
                onPressed: () {},
                text: "Send",
                color: Colors.blue,
                textColor: Colors.white,
              ),
            ],
          ),
        ),
      );

      expect(
        platformNodesWithId(tester, "primary_button_key").single,
        isSemantics(label: "Next", isButton: true, hasTapAction: true),
      );
      expect(
        platformNodesWithId(tester, "loading_primary_button_key").single,
        isSemantics(label: "Send", isButton: true, hasTapAction: true),
      );
      handle.dispose();
    });

    testWidgets("StackedButtons link-style secondary button", (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        wrap(
          StackedButtons(
            primaryText: "Create",
            onPrimary: () {},
            secondaryText: "Restore",
            onSecondary: () {},
            secondaryAsLink: true,
            primaryKey: const ValueKey("welcome_create_button_key"),
            secondaryKey: const ValueKey("welcome_restore_button_key"),
          ),
        ),
      );

      expect(
        platformNodesWithId(tester, "welcome_create_button_key").single,
        isSemantics(label: "Create", isButton: true),
      );
      expect(
        platformNodesWithId(tester, "welcome_restore_button_key").single,
        isSemantics(label: "Restore", isButton: true),
      );
      handle.dispose();
    });
  });

  group("alert dialogs", () {
    testWidgets("two-action buttons get default ids and a button role", (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        wrap(
          AlertWithTwoActions(
            alertTitle: "Title",
            alertContent: "Content",
            leftButtonText: "Cancel",
            rightButtonText: "OK",
            actionLeftButton: () {},
            actionRightButton: () {},
          ),
        ),
      );

      expect(
        platformNodesWithId(tester, "alert_dialog_left_button_key").single,
        isSemantics(label: "Cancel", isButton: true, hasTapAction: true),
      );
      expect(
        platformNodesWithId(tester, "alert_dialog_right_button_key").single,
        isSemantics(label: "OK", isButton: true, hasTapAction: true),
      );
      handle.dispose();
    });

    testWidgets("a button test key overrides the default id", (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        wrap(
          AlertWithOneAction(
            alertTitle: "Title",
            alertContent: "Content",
            buttonText: "OK",
            buttonAction: () {},
            buttonKey: const ValueKey("send_page_confirm_ok_button_key"),
          ),
        ),
      );

      expect(
        platformNodesWithId(tester, "send_page_confirm_ok_button_key").single,
        isSemantics(label: "OK", isButton: true),
      );
      expect(find.byKey(const ValueKey("send_page_confirm_ok_button_key")), findsOneWidget);
      expect(find.bySemanticsIdentifier("alert_dialog_action_button_key"), findsNothing);
      handle.dispose();
    });

    testWidgets("a single action falls back to alert_dialog_action_button_key", (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        wrap(
          AlertWithOneAction(
            alertTitle: "Title",
            alertContent: "Content",
            buttonText: "OK",
            buttonAction: () {},
          ),
        ),
      );
      expect(platformNodesWithId(tester, "alert_dialog_action_button_key"), hasLength(1));
      handle.dispose();
    });
  });

  group("BaseTextFormField", () {
    testWidgets("a keyed field is a distinct text-field node with the identifier", (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        wrap(
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Header"),
              BaseTextFormField(
                key: const ValueKey("wallet_name_textfield_key"),
                hintText: "Wallet name",
              ),
            ],
          ),
        ),
      );

      final node = platformNodesWithId(tester, "wallet_name_textfield_key").single;
      expect(node, isSemantics(isTextField: true, label: "Wallet name"));
      expect(find.byKey(const ValueKey("wallet_name_textfield_key")), findsOneWidget);
      handle.dispose();
    });

    testWidgets("suffix buttons stay separate nodes next to the field", (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        wrap(
          BaseTextFormField(
            key: const ValueKey("send_page_address_textfield_key"),
            hintText: "Address",
            suffixIcon: IconButton(
              onPressed: () {},
              tooltip: "Paste",
              icon: const Icon(Icons.paste),
            ),
          ),
        ),
      );

      final field = platformNodesWithId(tester, "send_page_address_textfield_key").single;
      expect(field, isSemantics(isTextField: true, label: "Address"));
      final paste = tester.getSemantics(find.byTooltip("Paste"));
      expect(paste.isMergedIntoParent, isFalse);
      expect(paste, isSemantics(isButton: true, tooltip: "Paste"));
      handle.dispose();
    });

    testWidgets("a field without a hint still carries the identifier", (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        wrap(BaseTextFormField(key: const ValueKey("nameless_textfield_key"))),
      );
      expect(platformNodesWithId(tester, "nameless_textfield_key").single, isSemantics(isTextField: true));
      handle.dispose();
    });
  });

  group("toggle rows", () {
    testWidgets("ListItemToggleWidget is one node with label, toggled and id", (tester) async {
      final handle = tester.ensureSemantics();
      final node = await pumpAndFindOne(
        tester,
        ListItemToggleWidget(
          key: const ValueKey("settings_tor_toggle_key"),
          testId: "settings_tor_toggle_key",
          keyValue: "settings_tor_toggle_key",
          label: "Use Tor",
          value: true,
          onChanged: (_) {},
        ),
        "settings_tor_toggle_key",
      );
      expect(
        node,
        isSemantics(label: "Use Tor", hasToggledState: true, isToggled: true, hasTapAction: true),
      );
      handle.dispose();
    });

    testWidgets("SettingsSwitcherCell is one node with label, toggled and id", (tester) async {
      final handle = tester.ensureSemantics();
      final node = await pumpAndFindOne(
        tester,
        SettingsSwitcherCell(
          key: const ValueKey("privacy_settings_fiat_api_toggle_key"),
          title: "Disable fiat API",
          value: false,
          onValueChange: (_, __) {},
        ),
        "privacy_settings_fiat_api_toggle_key",
      );
      expect(node, isSemantics(label: "Disable fiat API", hasToggledState: true, isToggled: false));
      handle.dispose();
    });
  });

  group("list rows", () {
    testWidgets("SettingsCellWithArrow", (tester) async {
      final handle = tester.ensureSemantics();
      final node = await pumpAndFindOne(
        tester,
        SettingsCellWithArrow(
          testId: "settings_page_display_row_key",
          title: "Display settings",
          handler: (_) {},
        ),
        "settings_page_display_row_key",
      );
      expect(node, isSemantics(label: "Display settings", isButton: true, hasTapAction: true));
      handle.dispose();
    });

    testWidgets("NewListSections applies ListItem.testId and never a keyValue", (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        wrap(
          NewListSections(
            sections: {
              "": [
                ListItemRegularRow(
                  keyValue: "/settings/display",
                  testId: "settings_page_display_row_key",
                  label: "Display",
                  onTap: () {},
                ),
                ListItemRegularRow(
                  keyValue: "/settings/security",
                  label: "Security",
                  onTap: () {},
                ),
                ListItemToggle(
                  keyValue: "settings_page_tor_toggle_key",
                  testId: "settings_page_tor_toggle_key",
                  label: "Tor",
                  value: false,
                  onChanged: (_) {},
                ),
                ListItemRegularRow(keyValue: "savings_key", label: "savings_key", onTap: () {}),
              ],
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        platformNodesWithId(tester, "settings_page_display_row_key").single,
        isSemantics(label: "Display", hasTapAction: true),
      );
      expect(
        platformNodesWithId(tester, "settings_page_tor_toggle_key").single,
        isSemantics(label: "Tor", hasToggledState: true),
      );
      expect(find.bySemanticsIdentifier(RegExp("security")), findsNothing);
      expect(find.bySemanticsIdentifier(RegExp("savings")), findsNothing);
      handle.dispose();
    });
  });

  group("LineTabSwitcher", () {
    testWidgets("tabs get index-based ids on their existing button nodes", (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        wrap(LineTabSwitcher(tabs: const ["Send", "Receive"], selectedTab: 1, onTabChange: (_) {})),
      );
      await tester.pumpAndSettle();

      expect(
        platformNodesWithId(tester, "line_tab_switcher_1_key").single,
        isSemantics(label: "Receive", isButton: true, isSelected: true),
      );
      expect(platformNodesWithId(tester, "line_tab_switcher_0_key"), hasLength(1));
      handle.dispose();
    });
  });
}

import "package:cake_wallet/di.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/locales/locale.dart";
import "package:cake_wallet/src/screens/settings/widgets/settings_choices_cell.dart";
import "package:cake_wallet/src/screens/settings/widgets/settings_switcher_cell.dart";
import "package:cake_wallet/src/widgets/new_list_row/list_item_toggle_widget.dart";
import "package:cake_wallet/src/widgets/picker.dart";
import "package:cake_wallet/src/widgets/standard_switch.dart";
import "package:cake_wallet/themes/core/theme_store.dart";
import "package:cake_wallet/view_model/settings/choices_list_item.dart";
import "package:flutter/material.dart";
import "package:flutter/semantics.dart";
import "package:flutter_test/flutter_test.dart";

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

  Future<void> pump(WidgetTester tester, Widget child) => tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: localizationDelegates,
          supportedLocales: S.delegate.supportedLocales,
          home: Scaffold(body: child),
        ),
      );

  testWidgets("ListItemToggleWidget switch is named by its row title", (tester) async {
    final handle = tester.ensureSemantics();
    await pump(
      tester,
      ListItemToggleWidget(
        key: const ValueKey("auto_generate_subaddresses"),
        keyValue: "auto_generate_subaddresses",
        label: "Auto generate addresses",
        value: false,
        onChanged: (_) {},
      ),
    );

    expect(find.bySemanticsLabel("Auto generate addresses"), findsOneWidget);
    expect(
      tester.getSemantics(find.byType(StandardSwitch)),
      containsSemantics(
        label: "Auto generate addresses",
        hasToggledState: true,
        isToggled: false,
        hasTapAction: true,
      ),
    );
    handle.dispose();
  });

  testWidgets("SettingsSwitcherCell switch is named by its row title", (tester) async {
    final handle = tester.ensureSemantics();
    await pump(
      tester,
      SettingsSwitcherCell(
        title: "Disable service status bulletin",
        value: true,
        onValueChange: (_, __) {},
      ),
    );

    expect(find.bySemanticsLabel("Disable service status bulletin"), findsOneWidget);
    expect(
      tester.getSemantics(find.byType(StandardSwitch)),
      containsSemantics(
        label: "Disable service status bulletin",
        hasToggledState: true,
        isToggled: true,
        hasTapAction: true,
      ),
    );
    handle.dispose();
  });

  testWidgets("SettingsSwitcherCell with onTap keeps row and switch actions apart", (tester) async {
    final handle = tester.ensureSemantics();
    var opened = 0;
    bool? toggledTo;
    await pump(
      tester,
      SettingsSwitcherCell(
        title: "Tether USD (USDT)",
        value: false,
        onValueChange: (_, value) => toggledTo = value,
        onTap: (_) => opened++,
      ),
    );

    final switchNode = tester.getSemantics(find.byType(StandardSwitch));
    expect(
      switchNode,
      containsSemantics(
        label: "Tether USD (USDT)",
        hasToggledState: true,
        isToggled: false,
        hasTapAction: true,
      ),
    );
    switchNode.owner!.performAction(switchNode.id, SemanticsAction.tap);
    expect(toggledTo, true);
    expect(opened, 0);

    final rowNode = tester.getSemantics(find.byType(TextButton));
    expect(rowNode.id, isNot(switchNode.id));
    rowNode.owner!.performAction(rowNode.id, SemanticsAction.tap);
    expect(opened, 1);
    handle.dispose();
  });

  testWidgets("SettingsChoicesCell options expose selected state", (tester) async {
    final handle = tester.ensureSemantics();
    await pump(
      tester,
      SettingsChoicesCell(
        ChoicesListItem<String>(
          title: "Fiat API",
          items: const ["Enabled", "Tor only", "Disabled"],
          selectedItem: "Tor only",
        ),
      ),
    );

    expect(
      tester.getSemantics(find.text("Tor only")),
      containsSemantics(
        label: "Tor only",
        isButton: true,
        isSelected: true,
        isInMutuallyExclusiveGroup: true,
      ),
    );
    expect(
      tester.getSemantics(find.text("Enabled")),
      containsSemantics(label: "Enabled", isSelected: false, isInMutuallyExclusiveGroup: true),
    );
    handle.dispose();
  });

  testWidgets("Picker items expose selected state", (tester) async {
    final handle = tester.ensureSemantics();
    await pump(
      tester,
      Picker<String>(
        items: const ["Enabled", "Tor only", "Disabled"],
        selectedAtIndex: 0,
        onItemSelected: (_) {},
        isSeparated: false,
      ),
    );

    expect(
      tester.getSemantics(find.text("Enabled")),
      containsSemantics(
        label: "Enabled",
        isButton: true,
        isSelected: true,
        isInMutuallyExclusiveGroup: true,
      ),
    );
    expect(
      tester.getSemantics(find.text("Tor only")),
      containsSemantics(label: "Tor only", isSelected: false, isInMutuallyExclusiveGroup: true),
    );
    handle.dispose();
  });
}

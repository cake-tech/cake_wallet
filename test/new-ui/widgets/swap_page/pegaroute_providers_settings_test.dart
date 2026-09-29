import 'package:cake_wallet/di.dart';
import 'package:cake_wallet/exchange/provider/pegaroute/pegaroute_provider_preferences.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/new-ui/widgets/swap_page/pegaroute_providers_settings.dart';
import 'package:cake_wallet/src/widgets/new_list_row/list_item_toggle_widget.dart';
import 'package:cake_wallet/themes/core/theme_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobx/mobx.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('all four providers are decentralized and explicit disables survive mode toggles',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final storage = await SharedPreferences.getInstance();
    final preferences = PegarouteProviderPreferences(storage);
    final decentralizedOnly = Observable(false);
    getIt.registerSingleton<ThemeStore>(ThemeStore());
    addTearDown(() => getIt.unregister<ThemeStore>());
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('en'),
      supportedLocales: S.delegate.supportedLocales,
      localizationsDelegates: [S.delegate],
      home: Scaffold(
        body: PegarouteProvidersSettings(
          preferences: preferences,
          decentralizedOnly: () => decentralizedOnly.value,
        ),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Pegaroute Providers'), findsOneWidget);
    expect(find.text(S.current.decentralized), findsNWidgets(4));
    expect(find.text(S.current.centralized), findsNothing);
    expect(find.byType(ListItemToggleWidget), findsNWidgets(4));
    await tester.tap(find.text('OpenOcean'));
    await tester.pumpAndSettle();
    expect(PegarouteProviderPreferences(storage).isEnabled('openocean'), false);
    runInAction(() => decentralizedOnly.value = true);
    await tester.pumpAndSettle();
    expect(find.byType(ListItemToggleWidget), findsNWidgets(4));
    expect(find.text(S.current.decentralized_only), findsNothing);
    expect(preferences.isEnabled('instaswap'), true);
    await tester.tap(find.text('Instaswap'));
    await tester.pumpAndSettle();
    expect(PegarouteProviderPreferences(storage).isEnabled('instaswap'), false);
    runInAction(() => decentralizedOnly.value = false);
    await tester.pumpAndSettle();
    expect(find.byType(ListItemToggleWidget), findsNWidgets(4));
    expect(preferences.isEnabled('instaswap'), false);
    expect(find.text(S.current.decentralized), findsNWidgets(4));
    expect(tester.takeException(), isNull);
  });
}

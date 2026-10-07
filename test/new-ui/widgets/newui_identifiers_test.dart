import "package:cake_wallet/core/auth_service.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/locales/locale.dart";
import "package:cake_wallet/new-ui/pages/settings_page.dart";
import "package:cake_wallet/new-ui/widgets/confirm_swiper.dart";
import "package:cake_wallet/new-ui/widgets/receive_page/receive_bottom_buttons.dart";
import "package:cake_wallet/new-ui/widgets/send_page/send_amount_input.dart";
import "package:cake_wallet/view_model/dashboard/dashboard_view_model.dart";
import "package:cw_core/balance.dart";
import "package:cw_core/transaction_history.dart";
import "package:cw_core/transaction_info.dart";
import "package:cw_core/wallet_base.dart";
import "package:cw_core/wallet_type.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_test/flutter_test.dart";
import "package:mocktail/mocktail.dart";

import "../../utils/semantics_helpers.dart";

class _MockDashboardViewModel extends Mock implements DashboardViewModel {}

class _MockAuthService extends Mock implements AuthService {}

class _MockWallet extends Mock
    implements WalletBase<Balance, TransactionHistoryBase<TransactionInfo>, TransactionInfo> {}

void main() {
  setUpAll(() => S.delegate.load(const Locale("en")));

  Widget wrap(Widget child) => MaterialApp(
        localizationsDelegates: localizationDelegates,
        supportedLocales: S.delegate.supportedLocales,
        home: Scaffold(body: child),
      );

  testWidgets("settings rows and top bar carry settings_page ids", (tester) async {
    final handle = tester.ensureSemantics();
    final dashboardViewModel = _MockDashboardViewModel();
    final wallet = _MockWallet();
    when(() => dashboardViewModel.wallet).thenReturn(wallet);
    when(() => dashboardViewModel.hasLightning).thenReturn(false);
    when(() => dashboardViewModel.hasWalletConnect).thenReturn(false);
    when(() => wallet.type).thenReturn(WalletType.monero);
    when(() => wallet.hardwareWalletType).thenReturn(null);
    when(() => wallet.hasAccountsSupport).thenReturn(true);

    await tester.pumpWidget(
      wrap(SettingsMainPage(dashboardViewModel: dashboardViewModel, authService: _MockAuthService())),
    );
    await tester.pumpAndSettle();

    for (final (id, label) in [
      ("settings_page_wallet_accounts_row_key", S.current.accounts),
      ("settings_page_privacy_row_key", S.current.privacy),
      ("settings_page_display_settings_row_key", S.current.display),
      ("settings_page_security_backup_row_key", S.current.security),
      ("settings_page_about_row_key", S.current.about),
    ]) {
      expect(
        platformNodesWithId(tester, id).single,
        isSemantics(label: label, hasTapAction: true),
        reason: id,
      );
    }
    expect(platformNodesWithId(tester, "settings_page_top_bar_title_key"), hasLength(1));
    expect(platformNodesWithId(tester, "settings_page_top_bar_leading_key"), hasLength(1));
    expect(find.bySemanticsIdentifier(RegExp("lightning_username")), findsNothing);
    handle.dispose();
  });

  testWidgets("send amount field keeps its own text-field node with the id", (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      wrap(
        NewSendAmountInput(
          key: const ValueKey("send_page_amount_input_key"),
          currency: "XMR",
          maxDecimals: 12,
          hasPicker: false,
          onPickerClicked: () {},
          currencyIconPath: "",
          amountController: TextEditingController(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      platformNodesWithId(tester, "send_page_amount_input_key").single,
      isSemantics(isTextField: true),
    );
    handle.dispose();
  });

  testWidgets("confirm swiper exposes its key as the identifier", (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      wrap(
        ConfirmSwiper(
          key: const ValueKey("send_page_confirm_swiper_key"),
          onConfirmed: () {},
          swiperText: "Swipe to send",
        ),
      ),
    );
    await tester.pump();

    expect(
      platformNodesWithId(tester, "send_page_confirm_swiper_key").single,
      isSemantics(label: "Swipe to send"),
    );
    handle.dispose();
  });

  testWidgets("receive bottom buttons carry receive_page ids", (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      wrap(
        ReceiveBottomButtons(
          largeQrMode: false,
          onCopyButtonPressed: () {},
          onAccountsButtonPressed: () {},
          onAmountButtonPressed: () {},
          onLabelButtonPressed: () {},
          showLabelButton: true,
          showAccountsButton: true,
          copyData: const ClipboardData(text: "address"),
        ),
      ),
    );
    await tester.pumpAndSettle();

    for (final (id, label) in [
      ("receive_page_copy_button_key", S.current.copy),
      ("receive_page_set_amount_button_key", S.current.set_amount),
      ("receive_page_label_button_key", S.current.label),
      ("receive_page_addresses_button_key", S.current.addresses),
    ]) {
      expect(
        platformNodesWithId(tester, id).single,
        isSemantics(label: label, isButton: true, hasTapAction: true),
        reason: id,
      );
    }
    handle.dispose();
  });
}

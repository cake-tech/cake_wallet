import "package:cake_wallet/new-ui/widgets/coins_page/assets_history/assets_history_section.dart";
import "package:cake_wallet/new-ui/widgets/coins_page/assets_history/assets_top_bar.dart";
import "package:cake_wallet/view_model/dashboard/dashboard_view_model.dart";
import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:mocktail/mocktail.dart";

class _MockDashboardViewModel extends Mock implements DashboardViewModel {}

void main() {
  testWidgets("uses the larger assets gap only for EVM wallets", (tester) async {
    final dashboardViewModel = _MockDashboardViewModel();
    const tabs = [AssetsHistorySectionTab("Assets", SizedBox.shrink(), null)];

    Future<EdgeInsetsGeometry> pumpTopBar({required bool isEVMWallet}) async {
      when(() => dashboardViewModel.isEVMWallet).thenReturn(isEVMWallet);

      await tester.pumpWidget(
        MaterialApp(
          home: CustomScrollView(
            slivers: [
              AssetsTopBar(
                onTabChange: (_) {},
                onTransactionHistoryOpened: () {},
                selectedTab: 0,
                tabs: tabs,
                dashboardViewModel: dashboardViewModel,
              ),
            ],
          ),
        ),
      );

      final sliver = tester.widget<SliverToBoxAdapter>(
        find.descendant(
          of: find.byType(AssetsTopBar),
          matching: find.byType(SliverToBoxAdapter),
        ),
      );

      return (sliver.child! as Padding).padding;
    }

    expect(
      await pumpTopBar(isEVMWallet: true),
      const EdgeInsets.only(top: 24, left: 12, right: 18),
    );
    expect(
      await pumpTopBar(isEVMWallet: false),
      const EdgeInsets.only(top: 20, left: 12, right: 18),
    );
  });
}

import 'package:cake_wallet/di.dart';
import 'package:cake_wallet/src/screens/dashboard/desktop_widgets/desktop_action_button.dart';
import 'package:cake_wallet/src/screens/dashboard/pages/cake_features_page.dart';
import 'package:cake_wallet/view_model/dashboard/dashboard_view_model.dart';
import 'package:cake_wallet/view_model/dashboard/cake_features_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

class DesktopDashboardActions extends StatelessWidget {
  final DashboardViewModel dashboardViewModel;

  const DesktopDashboardActions(this.dashboardViewModel, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: Observer(builder: (_) {
        return Column(
          children: [
            const SizedBox(height: 16),
            Row(
              children: [
              ],
            ),
            Row(
              children: [
              ],
            ),
            Expanded(
              child: CakeFeaturesPage(
                dashboardViewModel: dashboardViewModel,
                cakeFeaturesViewModel: getIt.get<CakeFeaturesViewModel>(),
              ),
            ),
          ],
        );
      }),
    );
  }
}

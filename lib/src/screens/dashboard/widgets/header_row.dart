import 'package:cake_wallet/src/screens/dashboard/widgets/filter_widget.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/view_model/dashboard/dashboard_view_model.dart';

class HeaderRow extends StatelessWidget {
  HeaderRow({required this.dashboardViewModel, super.key});

  final DashboardViewModel dashboardViewModel;

  @override
  Widget build(BuildContext context) {
    final filterIcon = Image.asset('assets/images/filter_icon.png',
        color: Theme.of(context).colorScheme.onSurface);

    return Container(
      height: 52,
      color: Colors.transparent,
      padding: EdgeInsets.only(left: 24, right: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Text(
            S.of(context).transactions,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface),
          ),
          Semantics(
            container: true,
            child: GestureDetector(
              key: ValueKey('transactions_page_header_row_transaction_filter_button_key'),
              onTap: () {
                showPopUp<void>(
                  context: context,
                  builder: (context) => FilterWidget(filterItems: dashboardViewModel.filterItems),
                );
              },
              child: Semantics(
                label: 'Transaction Filter',
                button: true,
                enabled: true,
                child: Container(
                  height: 36,
                  width: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context).colorScheme.surfaceContainer,
                  ),
                  child: filterIcon,
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
import "dart:ui";

import "package:cake_wallet/new-ui/pages/more_actions_modal.dart";
import "package:cake_wallet/src/screens/dashboard/widgets/new_main_navbar_widget.dart";
import "package:cake_wallet/src/widgets/cake_image_widget.dart";
import "package:cake_wallet/view_model/dashboard/dashboard_view_model.dart";
import "package:flutter/material.dart";
import "package:modal_bottom_sheet/modal_bottom_sheet.dart";

class MoreActionsButton extends StatelessWidget {
  const MoreActionsButton({required this.dashboardViewModel, super.key});

  final DashboardViewModel dashboardViewModel;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(99999999),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
      child: GestureDetector(
            onTap: () {
              showMaterialModalBottomSheet(
                  backgroundColor: Colors.transparent,
                  context: context,
                  builder: (context) => MoreActionsModal(dashboardViewModel: dashboardViewModel));
            },
            child: Container(
                width: NewMainNavBar.barHeight,
                height: NewMainNavBar.barHeight,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999999),
                  color: Theme.of(context).colorScheme.surfaceContainer.withAlpha(127),
                  border: Border.all(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(127),
                      width: 1),
                ),
                child: Icon(
                  Icons.add,
                  size: 36,
                  color: Theme.of(context).colorScheme.primary,
                )),
          ),
    ),
  );
}

import "package:bloc_presentation/bloc_presentation.dart";
import "package:cake_wallet/core/wallet_network.dart";
import "package:cake_wallet/entities/new_ui_entities/list_item/list_Item_checkbox.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/viewmodels/wallet_network/manage_builtin_networks_cubit.dart";
import "package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart";
import "package:cake_wallet/src/widgets/alert_with_one_action.dart";
import "package:cake_wallet/src/widgets/cake_image_widget.dart";
import "package:cake_wallet/src/widgets/new_list_row/new_list_section.dart";
import "package:cake_wallet/utils/responsive_layout_util.dart";
import "package:cake_wallet/utils/show_pop_up.dart";
import "package:cw_core/wallet_type.dart";
import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";

class ManageBuiltinNetworksPage extends StatelessWidget {
  const ManageBuiltinNetworksPage({required this.cubit, super.key});

  final ManageBuiltinNetworksCubit cubit;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return BlocProvider<ManageBuiltinNetworksCubit>(
      create: (_) => cubit,
      child: Material(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [colors.surface, colors.surfaceDim],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: ResponsiveLayoutUtilBase.kDesktopMaxWidthConstraint,
                ),
                child: Column(
                  children: [
                    ModalTopBar(
                      title: S.of(context).manage_builtin_networks,
                      leadingIcon: const Icon(Icons.arrow_back_ios_new),
                      leadingSemanticLabel: S.of(context).seed_alert_back,
                      onLeadingPressed: () => Navigator.of(context).maybePop(),
                      padding: const EdgeInsets.all(20),
                      titleStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.08,
                          ),
                    ),
                    Expanded(
                      child: BlocPresentationListener<ManageBuiltinNetworksCubit,
                          ManageBuiltinNetworksPresentation>(
                        listener: (context, event) => switch (event) {
                          LastVisibleNetworkHideRefused() => showPopUp<void>(
                              context: context,
                              builder: (dialogContext) => AlertWithOneAction(
                                alertTitle: S.of(dialogContext).warning,
                                alertContent: S.of(dialogContext).at_least_one_network_visible,
                                buttonText: S.of(dialogContext).ok,
                                buttonKey: const ValueKey(
                                  "manage_builtin_networks_refusal_ok_button_key",
                                ),
                                buttonAction: () => Navigator.of(dialogContext).pop(),
                              ),
                            ),
                        },
                        child: BlocBuilder<ManageBuiltinNetworksCubit, ManageBuiltinNetworksState>(
                          builder: (context, state) => SingleChildScrollView(
                            key: const ValueKey("manage_builtin_networks_scrollable_key"),
                            padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
                            child: Column(
                              children: [
                                const CakeImageWidget(
                                  imageUrl: "assets/new-ui/network_visibility.svg",
                                  width: 75,
                                  height: 75,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  S.of(context).manage_builtin_networks_description,
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: colors.onSurfaceVariant,
                                        letterSpacing: -0.06,
                                      ),
                                ),
                                const SizedBox(height: 24),
                                NewListSections(
                                  isDense: true,
                                  sections: {
                                    "": [
                                      for (final type in state.networks)
                                        ListItemCheckbox(
                                          keyValue: "manage_builtin_networks_${type.name}_row_key",
                                          label: walletTypeToDisplayName(type),
                                          iconPath: builtinNetworkIconPath(type),
                                          value: state.isVisible(type),
                                          onChanged: (_) => context
                                              .read<ManageBuiltinNetworksCubit>()
                                              .toggleVisibility(type),
                                        ),
                                    ],
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

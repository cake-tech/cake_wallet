import "dart:math";

import "package:cake_wallet/core/utilities.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/viewmodels/card_customizer/card_customizer_bloc.dart";
import "package:cake_wallet/new-ui/widgets/account_confirmation_content.dart";
import "package:cake_wallet/new-ui/widgets/coins_page/cards/balance_card.dart";
import "package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart";
import "package:cake_wallet/src/widgets/alert_with_two_actions.dart";
import "package:cake_wallet/src/widgets/base_alert_dialog.dart";
import "package:cake_wallet/src/widgets/cake_image_widget.dart";
import "package:cake_wallet/src/widgets/new_list_row/list_Item_style_wrapper.dart";
import "package:cake_wallet/utils/show_pop_up.dart";
import "package:cake_wallet/view_model/dashboard/dashboard_view_model.dart";
import "package:cake_wallet/view_model/monero_account_list/account_list_item.dart";
import "package:cake_wallet/view_model/monero_account_list/monero_account_list_view_model.dart";
import "package:cw_core/card_design.dart";
import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";

class CardCustomizer extends StatefulWidget {
  const CardCustomizer({
    required this.cryptoTitle,
    required this.cryptoName,
    required this.dashboardViewModel,
    this.account,
    this.accountListViewModel,
    this.fiatBalance = "",
    super.key,
  });

  final String cryptoTitle;
  final String cryptoName;
  final DashboardViewModel dashboardViewModel;
  final AccountListItem? account;
  final MoneroAccountListViewModel? accountListViewModel;
  final String fiatBalance;

  @override
  State<CardCustomizer> createState() => _CardCustomizerState();
}

class _CardCustomizerState extends State<CardCustomizer> {
  final accountNameController = TextEditingController();
  late final CardCustomizerBloc bloc;

  bool get _isAccount => widget.account != null;

  @override
  void initState() {
    super.initState();

    bloc = context.read<CardCustomizerBloc>();

    if (bloc.state is! CardCustomizerNotLoaded) {
      accountNameController.text = bloc.state.accountName;
    }
  }

  bool _showIconStylePanel(CardCustomizerState state) {
    final design = state.availableDesigns[state.selectedDesignIndex];
    return design.backgroundType == CardDesignBackgroundTypes.svgIcon &&
        state.availableIconPaths.isNotEmpty;
  }

  CardDesign _cardStylePreviewDesign(CardCustomizerState state, int index) {
    var design = state.availableDesigns[index].withGradient(state.selectedColor);
    if (design.backgroundType == CardDesignBackgroundTypes.svgIcon &&
        state.availableIconPaths.isNotEmpty) {
      design = design.withIcon(state.availableIconPaths[state.selectedIconIndex]);
    }
    return design;
  }

  Future<void> _requestArchive() async {
    final latestAccount = widget.accountListViewModel!.accounts
            .firstWhereOrNull((item) => item.id == widget.account!.id) ??
        widget.account!;
    final account = AccountListItem(
      id: latestAccount.id,
      label: bloc.state.accountName,
      balance: latestAccount.balance,
      isSelected: latestAccount.isSelected,
    );
    final isFunded = isAccountFunded(account);
    final confirmed = await showPopUp<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertWithTwoActions(
        alertTitle: isFunded
            ? S.of(dialogContext).archive_account_confirmation_title
            : S.of(dialogContext).archive_account_title,
        alertContent: "",
        alertContentTextWidget: ArchiveConfirmationContent(
          account: account,
          accountListViewModel: widget.accountListViewModel!,
          dashboardViewModel: widget.dashboardViewModel,
          isFunded: isFunded,
        ),
        leftButtonText: S.of(dialogContext).cancel,
        rightButtonText: S.of(dialogContext).continue_text,
        leftAlertButtonStyle: AlertButtonStyle.primary(dialogContext),
        rightAlertButtonStyle: AlertButtonStyle.secondary(dialogContext),
        actionLeftButton: () => Navigator.of(dialogContext).pop(false),
        actionRightButton: () => Navigator.of(dialogContext).pop(true),
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }
    Navigator.of(context).pop(true);
  }

  @override
  void dispose() {
    accountNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => BlocListener<CardCustomizerBloc, CardCustomizerState>(
        listenWhen: (previous, current) => previous.accountName != current.accountName,
        listener: (context, state) {
          if (accountNameController.text != state.accountName) {
            accountNameController.text = state.accountName;
          }
        },
        child: BlocBuilder<CardCustomizerBloc, CardCustomizerState>(
          builder: (context, state) {
            if (state is CardCustomizerNotLoaded) {
              return const SizedBox.shrink();
            }
            return PopScope(
              child: SingleChildScrollView(
                child: SafeArea(
                  child: Column(
                    spacing: 25,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ModalTopBar(
                        title: _isAccount ? S.of(context).edit_account : S.of(context).edit_card,
                        subtitle: _isAccount ? "#${widget.account!.id + 1}" : null,
                        leadingIcon:
                            Icon(_isAccount ? Icons.arrow_back_ios_new : Icons.close, size: 18),
                        leadingSemanticLabel:
                            _isAccount ? S.of(context).seed_alert_back : S.of(context).close,
                        onLeadingPressed: () => Navigator.of(context).maybePop(),
                      ),
                      BalanceCard(
                        width: min(MediaQuery.of(context).size.width * 0.87, 768),
                        selected: true,
                        designSwitchDuration: const Duration(milliseconds: 300),
                        accountIndex: _isAccount ? widget.account!.id + 1 : null,
                        accountName: !_isAccount
                            ? ""
                            : state.accountName.trim().isEmpty
                                ? S.of(context).unnamed_account
                                : state.accountName,
                        balance: widget.account?.balance ?? "0.00",
                        fiatBalance: widget.fiatBalance,
                        assetName: state.displaySats ? "sats" : widget.cryptoName,
                        capitalizeAssetName: !state.displaySats,
                        design: state.selectedDesign,
                      ),
                      if (_isAccount)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                          child: Column(
                            spacing: 8,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(S.of(context).account_name),
                              TextField(
                                maxLength: 32,
                                decoration: const InputDecoration(counterText: ""),
                                onChanged: (value) {
                                  context.read<CardCustomizerBloc>().add(AccountNameChanged(value));
                                },
                                controller: accountNameController,
                              ),
                            ],
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceContainer,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  spacing: 8,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(S.of(context).card_style),
                                    SizedBox(
                                      height: 63,
                                      child: ListView.separated(
                                        scrollDirection: Axis.horizontal,
                                        itemCount: state.availableDesigns.length,
                                        separatorBuilder: (context, index) =>
                                            const SizedBox(width: 8),
                                        itemBuilder: (context, index) => GestureDetector(
                                          onTap: () {
                                            context
                                                .read<CardCustomizerBloc>()
                                                .add(CardDesignSelected(index));
                                          },
                                          child: AnimatedContainer(
                                            duration: const Duration(milliseconds: 300),
                                            decoration: ShapeDecoration(
                                              shape: RoundedSuperellipseBorder(
                                                side: BorderSide(
                                                  color: ((index == state.selectedDesignIndex)
                                                      ? Theme.of(context).colorScheme.onSurface
                                                      : Colors.transparent),
                                                  width: 1,
                                                ),
                                                borderRadius: BorderRadiusGeometry.circular(12),
                                              ),
                                            ),
                                            child: AnimatedScale(
                                              duration: const Duration(milliseconds: 200),
                                              scale: index == state.selectedDesignIndex ? 0.94 : 1,
                                              child: BalanceCard(
                                                width: 96,
                                                borderRadius: 10,
                                                selected: false,
                                                designSwitchDuration:
                                                    const Duration(milliseconds: 300),
                                                design: _cardStylePreviewDesign(state, index),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 350),
                                switchInCurve: Curves.easeOut,
                                switchOutCurve: Curves.easeIn,
                                transitionBuilder: (child, animation) => FadeTransition(
                                  opacity: animation,
                                  child: SizeTransition(
                                    sizeFactor: animation,
                                    axisAlignment: -1,
                                    child: child,
                                  ),
                                ),
                                child: _showIconStylePanel(state)
                                    ? Column(
                                        key: const ValueKey("icon_style_panel"),
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const SizedBox(height: 8),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 12),
                                            child: Column(
                                              spacing: 8,
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(S.of(context).icon_style),
                                                SizedBox(
                                                  height: 48,
                                                  child: ListView.separated(
                                                    scrollDirection: Axis.horizontal,
                                                    itemCount: state.availableIconPaths.length,
                                                    separatorBuilder: (context, _) =>
                                                        const SizedBox(width: 8),
                                                    itemBuilder: (context, index) {
                                                      final icon = state.availableIconPaths[index];
                                                      final isSelected =
                                                          index == state.selectedIconIndex;
                                                      return GestureDetector(
                                                        onTap: () {
                                                          context
                                                              .read<CardCustomizerBloc>()
                                                              .add(IconStyleSelected(index));
                                                        },
                                                        child: AnimatedContainer(
                                                          duration:
                                                              const Duration(milliseconds: 200),
                                                          width: 48,
                                                          height: 48,
                                                          decoration: BoxDecoration(
                                                            borderRadius: BorderRadius.circular(18),
                                                            color: Theme.of(context).brightness ==
                                                                    Brightness.light
                                                                ? Theme.of(context)
                                                                    .colorScheme
                                                                    .onSurfaceVariant
                                                                    .withAlpha(64)
                                                                : Theme.of(context)
                                                                    .colorScheme
                                                                    .surfaceContainerHigh,
                                                            border: Border.all(
                                                              color: isSelected
                                                                  ? Theme.of(context)
                                                                      .colorScheme
                                                                      .onSurface
                                                                  : Colors.transparent,
                                                              width: 2,
                                                            ),
                                                          ),
                                                          child: Padding(
                                                            padding: const EdgeInsets.all(10),
                                                            child: CakeImageWidget(
                                                              imageUrl: icon.path,
                                                            ),
                                                          ),
                                                        ),
                                                      );
                                                    },
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      )
                                    : const SizedBox.shrink(key: ValueKey("icon_style_hidden")),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.surfaceContainerHigh,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    spacing: 8,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(S.of(context).color),
                                      SizedBox(
                                        width: double.infinity,
                                        child: Wrap(
                                          direction: Axis.horizontal,
                                          spacing: 4,
                                          runSpacing: 8,
                                          children: List.generate(
                                            state.availableColors.length,
                                            (index) => Material(
                                              borderRadius: BorderRadius.circular(999999999),
                                              child: InkWell(
                                                borderRadius: BorderRadius.circular(999999999),
                                                onTap: () {
                                                  context
                                                      .read<CardCustomizerBloc>()
                                                      .add(ColorSelected(index));
                                                },
                                                child: Stack(
                                                  children: [
                                                    AnimatedOpacity(
                                                      duration: const Duration(milliseconds: 200),
                                                      opacity:
                                                          index == state.selectedColorIndex ? 1 : 0,
                                                      child: Container(
                                                        width: 32,
                                                        height: 32,
                                                        decoration: BoxDecoration(
                                                          borderRadius:
                                                              BorderRadius.circular(99999999),
                                                          border: Border.all(
                                                            color: Theme.of(context)
                                                                .colorScheme
                                                                .onSurface,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    AnimatedScale(
                                                      duration: const Duration(milliseconds: 200),
                                                      scale: index == state.selectedColorIndex
                                                          ? 0.8
                                                          : 1,
                                                      child: Container(
                                                        width: 32,
                                                        height: 32,
                                                        decoration: BoxDecoration(
                                                          borderRadius:
                                                              BorderRadius.circular(99999999),
                                                          gradient: state.availableColors[index],
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
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (bloc.canHide)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
                          child: ListItemStyleWrapper(
                            isFirstInSection: true,
                            isLastInSection: true,
                            onTap: _requestArchive,
                            builder: (context, textStyle, labelStyle) => ConstrainedBox(
                              constraints: const BoxConstraints(minHeight: 40),
                              child: Row(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(2.5),
                                    child: CakeImageWidget(
                                      imageUrl: "assets/new-ui/archived.svg",
                                      width: 19,
                                      height: 19,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      spacing: 4,
                                      children: [
                                        Text(
                                          S.of(context).archive_account,
                                          style: textStyle.copyWith(
                                            height: 18 / 14,
                                            letterSpacing: -0.07,
                                          ),
                                        ),
                                        Text(
                                          S.of(context).archive_account_reversible,
                                          style: labelStyle.copyWith(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w400,
                                            height: 15 / 12,
                                            letterSpacing: -0.06,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  SizedBox.square(
                                    dimension: 16,
                                    child: Align(
                                      alignment: Alignment.centerRight,
                                      child: CakeImageWidget(
                                        imageUrl: "assets/new-ui/arrow_right.svg",
                                        width: 7,
                                        height: 12,
                                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      );
}

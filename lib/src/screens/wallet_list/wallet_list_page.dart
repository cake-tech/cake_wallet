import "dart:async";

import "package:another_flushbar/flushbar.dart";
import "package:cake_wallet/core/auth_service.dart";
import "package:cake_wallet/core/new_wallet_arguments.dart";
import "package:cake_wallet/entities/wallet_edit_page_arguments.dart";
import "package:cake_wallet/entities/wallet_list_order_types.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/monero/monero.dart";
import "package:cake_wallet/new-ui/widgets/image_widgets/wallet_icon_widget.dart";
import "package:cake_wallet/routes.dart";
import "package:cake_wallet/src/screens/auth/auth_page.dart";
import "package:cake_wallet/src/screens/base_page.dart";
import "package:cake_wallet/src/screens/connect_device/connect_device_page.dart";
import "package:cake_wallet/src/screens/dashboard/widgets/filter_list_widget.dart";
import "package:cake_wallet/src/screens/wallet_list/filtered_list.dart";
import "package:cake_wallet/src/screens/wallet_unlock/wallet_unlock_arguments.dart";
import "package:cake_wallet/src/widgets/alert_with_one_action.dart";
import "package:cake_wallet/src/widgets/cake_image_widget.dart";
import "package:cake_wallet/src/widgets/new_list_row/list_item_expansion_tile_widget.dart";
import "package:cake_wallet/src/widgets/new_list_row/list_item_regular_row_widget.dart";
import "package:cake_wallet/src/widgets/primary_button.dart";
import "package:cake_wallet/store/settings_store.dart";
import "package:cake_wallet/utils/exception_handler.dart";
import "package:cake_wallet/utils/feature_flag.dart";
import "package:cake_wallet/utils/responsive_layout_util.dart";
import "package:cake_wallet/utils/show_bar.dart";
import "package:cake_wallet/utils/show_pop_up.dart";
import "package:cake_wallet/view_model/hardware_wallet/ledger_view_model.dart";
import "package:cake_wallet/view_model/wallet_list/wallet_list_item.dart";
import "package:cake_wallet/view_model/wallet_list/wallet_list_view_model.dart";
import "package:cake_wallet/wallet_type_utils.dart";
import "package:cw_core/currency_for_wallet_type.dart";
import "package:cw_core/utils/print_verbose.dart";
import "package:cw_core/wallet_info.dart";
import "package:cw_core/wallet_type.dart";
import "package:flutter/material.dart";
import "package:flutter_mobx/flutter_mobx.dart";

class WalletListPage extends BasePage {
  WalletListPage({
    required this.walletListViewModel,
    required this.authService,
    this.onWalletLoaded,
  });

  @override
  bool get gradientBackground => true;

  final WalletListViewModel walletListViewModel;
  final AuthService authService;
  final Future<void> Function(BuildContext)? onWalletLoaded;

  @override
  String get title => S.current.wallets;

  @override
  Widget body(BuildContext context) => Observer(builder: (_) {
    if (walletListViewModel.multiWalletGroups.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    return WalletListBody(
      walletListViewModel: walletListViewModel,
      authService: authService,
      onWalletLoaded: onWalletLoaded ?? (context) => Navigator.of(context).pop(),
    );
  });

  @override
  Widget trailing(BuildContext context) => MergeSemantics(
    child: SizedBox(
      height: 37,
      width: 37,
      child: ButtonTheme(
        minWidth: double.minPositive,
        child: Semantics(
          container: true,
          child: GestureDetector(
            onTap: () async {
              await showPopUp<void>(
                context: context,
                builder: (context) => FilterListWidget(
                  initalType: walletListViewModel.orderType,
                  initalAscending: walletListViewModel.ascending,
                  onClose: (bool ascending, FilterListOrderType type) async {
                    walletListViewModel.setAscending(ascending);
                    await walletListViewModel.setOrderType(type);
                  },
                ),
              );
            },
            child: Semantics(
              label: "Filter wallets",
              button: true,
              enabled: true,
              child: Container(
                height: 36,
                width: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).colorScheme.surfaceContainer,
                ),
                child: Image.asset(
                  'assets/images/filter_icon.png',
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class WalletListBody extends StatefulWidget {
  WalletListBody({
    required this.walletListViewModel,
    required this.authService,
    required this.onWalletLoaded,
  });

  final WalletListViewModel walletListViewModel;
  final AuthService authService;
  final Function(BuildContext) onWalletLoaded;

  @override
  WalletListBodyState createState() => WalletListBodyState();
}

class WalletListBodyState extends State<WalletListBody> {
  final scrollController = ScrollController();
  final double tileHeight = 60;
  Flushbar<void>? _progressBar;

  bool _loadingWallet = false;

  @override
  Widget build(BuildContext context) => Container(
    height: double.infinity,
    padding: const EdgeInsets.only(top: 16),
    child: Stack(
      alignment: Alignment.bottomCenter,
      fit: StackFit.expand,
      children: <Widget>[
        SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 20, right: 20),
                child: Observer(
                  builder: (_) => FilteredList(
                    shrinkWrap: true,
                    list: widget.walletListViewModel.multiWalletGroups,
                    updateFunction: widget.walletListViewModel.reorderAccordingToWalletList,
                    itemBuilder: (context, index) {
                      final group = widget.walletListViewModel.multiWalletGroups[index];
                      final groupName = group.groupName ?? "";

                      final readyWallets = group.wallets
                          .where((walletInfo) => walletInfo.isReady)
                          .map((walletInfo) => widget.walletListViewModel
                          .convertWalletInfoToWalletListItem(walletInfo))
                          .toList();

                      final isExpanded = widget.walletListViewModel.expansionTileStateTrack[index] ??
                          readyWallets.any((wallet) => wallet.isCurrent);
                      widget.walletListViewModel.updateTileState(index, isExpanded);

                      return Padding(
                        key: ValueKey("group_wallets_expansion_tile_widget_${group.groupKey}"),
                        padding: const EdgeInsets.only(bottom: 12),
                        child: ListItemExpansionTileWidget(
                          keyValue: "group_wallets_expansion_tile_widget_$index",
                          label: groupName,
                          leadingWidget: group.icon != null
                              ? WalletIconAvatar(icon: group.icon, size: 32, contentSize: 24)
                              : CakeImageWidget(
                            imageUrl: "assets/new-ui/navbar/wallets.svg",
                            width: 28,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          isExpanded: isExpanded,
                          onExpansionChanged: (value) {
                            widget.walletListViewModel.updateTileState(index, value);
                            setState(() {});
                          },
                          isFirstInSection: true,
                          isLastInSection: true,
                          trailingWidget: Row(
                            children: [
                              InkWell(
                                onTap: () {
                                  final wallet = widget.walletListViewModel
                                      .convertWalletInfoToWalletListItem(group.wallets.first);
                                  Navigator.of(context).pushNamed(
                                    Routes.walletEdit,
                                    arguments: WalletEditPageArguments(
                                      walletListViewModel: widget.walletListViewModel,
                                      editingWallet: wallet,
                                      isWalletGroup: true,
                                      groupName: groupName,
                                      walletGroupKey: group.groupKey,
                                    ),
                                  );
                                },
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: CakeImageWidget(
                                    imageUrl: "assets/new-ui/pencil.svg",
                                    width: 24,
                                    color: Theme.of(context).colorScheme.onSurfaceVariant),
                                ),
                              ),
                              Icon(
                                isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                                size: 24,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ],
                          ),
                          children: List<Widget>.generate(readyWallets.length, (childIndex) {
                            final item = readyWallets[childIndex];
                            final isLastChild = childIndex == readyWallets.length - 1;
                            return ListItemRegularRowWidget(
                              key: ValueKey("${group.groupKey}_${item.name}"),
                              keyValue: "${group.groupKey}_${item.name}",
                              label: item.name,
                              iconPath: getCryptoCurrencyIconForWalletListItem(item.type),
                              showArrow: false,
                              isFirstInSection: false,
                              isLastInSection: isLastChild,
                              onTap: item.isCurrent ? null : () => _loadWallet(item),
                              leadingAccessory: item.isCurrent
                            );
                          }),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
        Stack(
          alignment: Alignment.bottomCenter,
          children: [
            !FeatureFlag.hasNewUi
                ? IgnorePointer(
              child: Container(
                alignment: Alignment.bottomCenter,
                height: 185,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: <Color>[
                      Theme.of(context).colorScheme.surface.withAlpha(10),
                      Theme.of(context).colorScheme.surface,
                      Theme.of(context).colorScheme.surface,
                      Theme.of(context).colorScheme.surface
                    ],
                  ),
                ),
              ),
            )
                : IgnorePointer(
              child: Container(
                height: 275,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: <Color>[
                      Theme.of(context).colorScheme.surfaceDim.withAlpha(10),
                      Theme.of(context).colorScheme.surfaceDim.withAlpha(150),
                      Theme.of(context).colorScheme.surfaceDim.withAlpha(255),
                      Theme.of(context).colorScheme.surfaceDim.withAlpha(255),
                      Theme.of(context).colorScheme.surfaceDim.withAlpha(255),
                      Theme.of(context).colorScheme.surfaceDim.withAlpha(255),
                      Theme.of(context).colorScheme.surfaceDim.withAlpha(255)
                    ],
                  ),
                ),
              ),
            ),
            Container(
              height: 240,
              width: MediaQuery.of(context).size.width,
              margin: EdgeInsets.only(bottom: 24),
              padding: EdgeInsets.only(left: 16, right: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  PrimaryImageButton(
                    image: Image.asset(
                      'assets/images/restore_wallet.png',
                      height: 12,
                      width: 12,
                      color: Theme.of(context).colorScheme.onSecondaryContainer,
                    ),
                    key: ValueKey('wallet_list_page_restore_wallet_button_key'),
                    onPressed: () {
                      if (widget
                          .walletListViewModel.shouldRequireTOTP2FAForCreatingNewWallets) {
                        widget.authService.authenticateAction(
                          context,
                          route: Routes.restoreOptions,
                          arguments: false,
                          conditionToDetermineIfToUse2FA: widget
                              .walletListViewModel.shouldRequireTOTP2FAForCreatingNewWallets,
                        );
                      } else {
                        Navigator.of(context)
                            .pushNamed(Routes.restoreOptions, arguments: false);
                      }
                    },
                    text: S.of(context).wallet_list_restore_wallet,
                    color: Theme.of(context).colorScheme.surfaceContainer,
                    textColor: Theme.of(context).colorScheme.onSecondaryContainer,
                  ),
                  SizedBox(height: 10.0),
                  PrimaryImageButton(
                    image: Image.asset(
                      'assets/images/new_wallet.png',
                      height: 12,
                      width: 12,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                    key: ValueKey('wallet_list_page_create_new_wallet_button_key'),
                    onPressed: () {
                      //TODO(David): Find a way to optimize this
                      if (isSingleCoin) {
                        if (widget
                            .walletListViewModel.shouldRequireTOTP2FAForCreatingNewWallets) {
                          widget.authService.authenticateAction(
                            context,
                            route: Routes.newWallet,
                            arguments: NewWalletArguments(
                              type: widget.walletListViewModel.currentWalletType,
                            ),
                            conditionToDetermineIfToUse2FA: widget
                                .walletListViewModel.shouldRequireTOTP2FAForCreatingNewWallets,
                          );
                        } else {
                          Navigator.of(context).pushNamed(
                            Routes.newWallet,
                            arguments: NewWalletArguments(
                              type: widget.walletListViewModel.currentWalletType,
                            ),
                          );
                        }
                      } else {
                        if (widget
                            .walletListViewModel.shouldRequireTOTP2FAForCreatingNewWallets) {
                          widget.authService.authenticateAction(
                            context,
                            route: Routes.walletCreationTypeSelectionPage,
                            conditionToDetermineIfToUse2FA: widget
                                .walletListViewModel.shouldRequireTOTP2FAForCreatingNewWallets,
                          );
                        } else {
                          Navigator.of(context).pushNamed(Routes.walletCreationTypeSelectionPage);
                        }
                      }
                    },
                    text: S.of(context).wallet_list_create_new_wallet,
                    color: Theme.of(context).colorScheme.primary,
                    textColor: Theme.of(context).colorScheme.onPrimary,
                  ),
                  if (FeatureFlag.hasNewUi) SizedBox(height: 52.0)
                ],
              ),
            ),
          ],
        ),
      ],
    ),
  );
  Future<void> _loadWallet(WalletListItem wallet) async {
    if (_loadingWallet) {
      printV("_loadWallet abandoned because _loadingWallet");
      return;
    }

    _loadingWallet = true;

    if (SettingsStoreBase.walletPasswordDirectInput) {
      Navigator.of(context).pushNamed(Routes.walletUnlockLoadable,
          arguments: WalletUnlockArguments(
              callback: (bool isAuthenticatedSuccessfully, AuthPageState auth) async {
                if (isAuthenticatedSuccessfully) {
                  auth.close();
                  setState(() {});
                }
              },
              walletName: wallet.name,
              walletType: wallet.type));
      _loadingWallet = false;
      return;
    }

    await widget.authService.authenticateAction(
      context,
      onAuthSuccess: (isAuthenticatedSuccessfully) async {
        if (!isAuthenticatedSuccessfully) {
          printV("!isAuthenticatedSuccessfully");
          _loadingWallet = false;
          return;
        }

        try {
          final requireHardwareWalletConnection =
          await widget.walletListViewModel.requireHardwareWalletConnection(wallet);
          if (requireHardwareWalletConnection) {
            bool didConnect = false;
            await Navigator.of(context).pushNamed(
              Routes.connectDevices,
              arguments: ConnectDevicePageParams(
                walletType: WalletType.monero,
                hardwareWalletType: HardwareWalletType.ledger,
                onConnectDevice: (context, ledgerVM) async {
                  if (ledgerVM is LedgerViewModel) {
                    monero!.setGlobalLedgerConnection(ledgerVM.connection);
                    didConnect = true;
                    Navigator.of(context).pop();
                  }
                },
                isReconnect: true,
              ),
            );

            if (!didConnect) return;

            showPopUp<void>(
              context: context,
              builder: (BuildContext context) => AlertWithOneAction(
                  alertTitle: S.of(context).proceed_on_device,
                  alertContent: S.of(context).proceed_on_device_description,
                  buttonText: S.of(context).cancel,
                  alertBarrierDismissible: false,
                  buttonAction: () => Navigator.of(context).pop()),
            );
          }
          changeProcessText(S.of(context).wallet_list_loading_wallet(wallet.name));
          await widget.walletListViewModel.loadWallet(wallet);
          // only pop the wallets route in mobile as it will go back to dashboard page
          // in desktop platforms the navigation tree is different
          unawaited(hideProgressText());
          if (responsiveLayoutUtil.shouldRenderMobileUI) {
            // await Future.delayed(Duration(seconds: 1));
            if (!this.mounted) return;
            if (!context.mounted) return;
            if (requireHardwareWalletConnection) {
              Navigator.of(context).pop();
            }
            await widget.onWalletLoaded.call(context);
          }
        } catch (e) {
          await ExceptionHandler.resetLastPopupDate();
          final err = e.toString();
          await ExceptionHandler.onError(FlutterErrorDetails(exception: err));
          if (this.mounted) {
            changeProcessText(S.of(context).wallet_list_failed_to_load(wallet.name, e.toString()));
          }
        } finally {
          _loadingWallet = false;
        }
      },
      conditionToDetermineIfToUse2FA:
      widget.walletListViewModel.shouldRequireTOTP2FAForAccessingWallet,
    );
    _loadingWallet = false;
  }

  void changeProcessText(String text) {
    try {
      if (_progressBar != null) {
        _progressBar!.dismiss();
      }
      _progressBar = createBar<void>(text, context, duration: null)..show(context);
    } catch (e) {}
  }

  Future<void> hideProgressText() async {
    await Future.delayed(Duration(milliseconds: 50), () {
      try {
        _progressBar?.dismiss();
        _progressBar = null;
      } catch (e) {}
    });
  }
}
import 'dart:async';

import 'package:another_flushbar/flushbar.dart';
import 'package:cake_wallet/core/auth_service.dart';
import 'package:cake_wallet/core/new_wallet_arguments.dart';
import 'package:cake_wallet/entities/wallet_edit_page_arguments.dart';
import 'package:cake_wallet/entities/wallet_list_order_types.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/monero/monero.dart';
import 'package:cake_wallet/new-ui/widgets/apps_widget.dart';
import 'package:cake_wallet/new-ui/widgets/modern_button.dart';
import 'package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/auth/auth_page.dart';
import 'package:cake_wallet/src/screens/connect_device/connect_device_page.dart';
import 'package:cake_wallet/src/screens/dashboard/widgets/filter_list_widget.dart';
import 'package:cake_wallet/src/screens/new_wallet/widgets/grouped_wallet_expansion_tile.dart';
import 'package:cake_wallet/src/screens/wallet_list/edit_wallet_button_widget.dart';
import 'package:cake_wallet/src/screens/wallet_list/filtered_list.dart';
import 'package:cake_wallet/src/screens/wallet_unlock/wallet_unlock_arguments.dart';
import 'package:cake_wallet/src/widgets/alert_with_one_action.dart';
import 'package:cake_wallet/src/widgets/cake_image_widget.dart';
import 'package:cake_wallet/src/widgets/gradient_background.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cake_wallet/utils/exception_handler.dart';
import 'package:cake_wallet/utils/responsive_layout_util.dart';
import 'package:cake_wallet/utils/show_bar.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:cake_wallet/view_model/hardware_wallet/ledger_view_model.dart';
import 'package:cake_wallet/view_model/wallet_list/wallet_list_item.dart';
import 'package:cake_wallet/view_model/wallet_list/wallet_list_view_model.dart';
import 'package:cake_wallet/wallet_type_utils.dart';
import 'package:cw_core/currency_for_wallet_type.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

class WalletListPage extends StatelessWidget {
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
  Widget build(BuildContext context) => Observer(builder: (_) {
        if (walletListViewModel.singleWalletsList.isEmpty &&
            walletListViewModel.multiWalletGroups.isEmpty) {
          return Center(
            child: CircularProgressIndicator(),
          );
        }
        return WalletListBody(
          walletListViewModel: walletListViewModel,
          authService: authService,
          onWalletLoaded: onWalletLoaded ?? (context) => Navigator.of(context).pop(),
        );
      });
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
  
  Widget trailing(BuildContext context){
    return Stack(
      children: [
        Text(
          S.current.wallets,
          style: Theme.of(context).textTheme.bodyMedium!.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: Container(
            height: 36,
            child: Row(
              spacing: 8,
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => {
                    showMaterialModalBottomSheet(
                        context: context,
                        backgroundColor: Colors.transparent,
                        builder: (context) {
                          return Container(
                            decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surface,
                                borderRadius:
                                BorderRadius.vertical(top: Radius.circular(16))),
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                  maxHeight: MediaQuery.of(context).size.height * 0.45),
                              child: Column(
                                children: [
                                  ModalTopBar(
                                    title: "Add Wallet",
                                    leadingIcon: Icon(Icons.close),
                                    onLeadingPressed: Navigator.of(context).pop,
                                  ),
                                  AppsWidget(
                                    isWide: true,
                                    onTap: () {
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
                                            route: Routes.newWalletType,
                                            conditionToDetermineIfToUse2FA: widget
                                                .walletListViewModel.shouldRequireTOTP2FAForCreatingNewWallets,
                                          );
                                        } else {
                                          Navigator.of(context).pushNamed(Routes.newWalletType);
                                        }
                                      }
                                    },
                                    title: S.current.create_new,
                                    subTitle:
                                    "Generate a new wallet for any supported coin",
                                    image: 'assets/new-ui/new-wallet.svg',
                                  ),
                                  AppsWidget(
                                    isWide: true,
                                    onTap: () {
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
                                    title: S.current.restore,
                                    subTitle:
                                    "Bring an existing wallet to Cake Wallet through multiple supported methods",
                                    image: 'assets/new-ui/restore.svg',
                                  ),
                                ],
                              ),
                            ),
                          );
                        })
                  },
                  style: TextButton.styleFrom(
                    shape: RoundedSuperellipseBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Icon(
                          Icons.add,
                          color: Theme.of(context).colorScheme.onInverseSurface
                      ),
                      Text(
                        S.current.add,
                        style: Theme.of(context).textTheme.labelMedium!.copyWith(
                          color: Theme.of(context).colorScheme.onInverseSurface,
                        ),
                      ),
                    ],
                  ),
                ),
                ModernButton(
                  iconColor: Theme.of(context).colorScheme.primary,
                  size: 36,
                  onPressed: () async {
                    await showPopUp<void>(
                      context: context,
                      builder: (context) => FilterListWidget(
                        initalType: widget.walletListViewModel.orderType,
                        initalAscending: widget.walletListViewModel.ascending,
                        onClose: (bool ascending, FilterListOrderType type) async {
                          widget.walletListViewModel.setAscending(ascending);
                          await widget.walletListViewModel.setOrderType(type);
                        },
                      ),
                    );
                  },
                  icon: Icon(Icons.filter_list_rounded),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
        scaffold: Container(
        height: double.infinity,
        padding: EdgeInsets.only(top: 80),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: trailing(context)
            ),
            SizedBox(height: 16.0),
            Expanded(
              child: Stack(
              alignment: Alignment.bottomCenter,
              fit: StackFit.expand,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SingleChildScrollView(
                    physics: AlwaysScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (widget.walletListViewModel.multiWalletGroups.isNotEmpty) ...{
                          Text(
                            S.current.shared_seed_wallets,
                            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                              fontWeight: FontWeight.w600,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                          ),
                          SizedBox(height: 8),
                          Container(
                            child: Observer(
                              builder: (_) => FilteredList(
                                shrinkWrap: true,
                                list: widget.walletListViewModel.multiWalletGroups,
                                updateFunction: widget.walletListViewModel.reorderAccordingToWalletList,
                                itemBuilder: (context, index) {
                                  final group = widget.walletListViewModel.multiWalletGroups[index];
                                  final groupName =
                                      group.groupName ?? '${S.current.wallet_group} ${index + 1}';

                                  widget.walletListViewModel.updateTileState(
                                    index,
                                    widget.walletListViewModel.expansionTileStateTrack[index] ?? false,
                                  );

                                  return GroupedWalletExpansionTile(
                                    onExpansionChanged: (value) {
                                      widget.walletListViewModel.updateTileState(index, value);
                                      setState(() {});
                                    },
                                    shouldShowCurrentWalletPointer: true,
                                    borderRadius: BorderRadius.all(Radius.circular(18)),
                                    title: groupName,
                                    tileKey: ValueKey('group_wallets_expansion_tile_widget_$index'),
                                    leadingWidget: CakeImageWidget(
                                      imageUrl: "assets/new-ui/navbar/wallets.svg",
                                      width: 28,
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    ),
                                    trailingWidget: EditWalletButtonWidget(
                                      width: 88,
                                      isGroup: true,
                                      isExpanded:
                                          widget.walletListViewModel.expansionTileStateTrack[index]!,
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
                                    ),
                                    childWallets: group.wallets.map((walletInfo) {
                                      return widget.walletListViewModel
                                          .convertWalletInfoToWalletListItem(walletInfo);
                                    }).toList(),
                                    isSelected: false,
                                    onChildItemTapped: (wallet) =>
                                        wallet.isCurrent ? null : _loadWallet(wallet),
                                    childTrailingWidget: (item) {
                                      return item.isCurrent
                                          ? SizedBox.shrink()
                                          : EditWalletButtonWidget(
                                              width: 64,
                                              onTap: () => Navigator.of(context).pushNamed(
                                                Routes.walletEdit,
                                                arguments: WalletEditPageArguments(
                                                  walletListViewModel: widget.walletListViewModel,
                                                  editingWallet: item,
                                                ),
                                              ),
                                            );
                                    },
                                  );
                                },
                              ),
                            ),
                          ),
                          SizedBox(height: 24),
                        },
                        if (widget.walletListViewModel.singleWalletsList.isNotEmpty) ...{
                          Text(
                            S.current.single_seed_wallets_group,
                            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                          SizedBox(height: 8.0),
                          Container(
                            child: Observer(
                              builder: (_) => FilteredList(
                                shrinkWrap: true,
                                list: widget.walletListViewModel.singleWalletsList,
                                updateFunction: widget.walletListViewModel.reorderAccordingToWalletList,
                                itemBuilder: (context, index) {
                                  final wallet = widget.walletListViewModel.singleWalletsList[index];
                                  final currentColor = wallet.isCurrent
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context).colorScheme.surface;
                                  return GroupedWalletExpansionTile(
                                    tileKey: ValueKey('single_wallets_expansion_tile_widget_$index'),
                                    isCurrentlySelectedWallet: wallet.isCurrent,
                                    leadingWidget: SizedBox(
                                      width: wallet.isCurrent ? 56 : 40,
                                      child: Row(
                                        children: [
                                          wallet.isCurrent
                                              ? Container(
                                                  height: 35,
                                                  width: 6,
                                                  margin: EdgeInsets.only(right: 16),
                                                  decoration: BoxDecoration(
                                                    borderRadius: BorderRadius.only(
                                                      topRight: Radius.circular(18),
                                                      bottomRight: Radius.circular(18),
                                                    ),
                                                    color: currentColor,
                                                  ),
                                                )
                                              : SizedBox(width: 6),
                                          Image.asset(
                                            getCryptoCurrencyIconForWalletListItem(
                                              wallet.type,
                                            ),
                                            width: 32,
                                            height: 32,
                                          ),
                                        ],
                                      ),
                                    ),
                                    title: wallet.name,
                                    isSelected: false,
                                    borderRadius: BorderRadius.all(Radius.circular(18)),
                                    margin: EdgeInsets.only(left: 20, right: 20, bottom: 12),
                                    onTitleTapped: () => wallet.isCurrent ? null : _loadWallet(wallet),
                                    trailingWidget: wallet.isCurrent
                                        ? null
                                        : EditWalletButtonWidget(
                                            width: 64,
                                            onTap: () {
                                              Navigator.of(context).pushNamed(
                                                Routes.walletEdit,
                                                arguments: WalletEditPageArguments(
                                                  walletListViewModel: widget.walletListViewModel,
                                                  editingWallet: wallet,
                                                ),
                                              );
                                            },
                                          ),
                                  );
                                },
                              ),
                            ),
                          ),
                        },
                        SizedBox(height: 250),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            ),
          ],
        ),
      ),
    );
  }

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
      _progressBar = createBar<void>(text, context, duration: null)
        ..show(context);
    }catch(e){}
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

import 'dart:async';

import 'package:another_flushbar/flushbar.dart';
import 'package:cake_wallet/core/auth_service.dart';
import 'package:cake_wallet/core/new_wallet_arguments.dart';
import 'package:cake_wallet/entities/wallet_edit_page_arguments.dart';
import "package:cake_wallet/entities/wallet_group.dart";
import 'package:cake_wallet/entities/wallet_list_order_types.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/monero/monero.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/auth/auth_page.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/screens/connect_device/connect_device_page.dart';
import 'package:cake_wallet/src/screens/dashboard/widgets/filter_list_widget.dart';
import 'package:cake_wallet/src/screens/new_wallet/widgets/grouped_wallet_expansion_tile.dart';
import 'package:cake_wallet/src/screens/wallet_list/edit_wallet_button_widget.dart';
import 'package:cake_wallet/src/screens/wallet_list/filtered_list.dart';
import 'package:cake_wallet/src/screens/wallet_unlock/wallet_unlock_arguments.dart';
import 'package:cake_wallet/src/widgets/alert_with_one_action.dart';
import 'package:cake_wallet/src/widgets/cake_image_widget.dart';
import 'package:cake_wallet/src/widgets/gradient_background.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
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

const _tileRadius = BorderRadius.all(Radius.circular(18));

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
  Widget body(BuildContext context) => Observer(
    builder: (_) {
      if (walletListViewModel.singleWalletsList.isEmpty &&
          walletListViewModel.multiWalletGroups.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }
      return WalletListBody(
        walletListViewModel: walletListViewModel,
        authService: authService,
        onWalletLoaded: onWalletLoaded ?? (context) => Navigator.of(context).pop(),
      );
    },
  );

  @override
  Widget trailing(BuildContext context) => _FilterButton(
    onTap: () => showPopUp<void>(
      context: context,
      builder: (context) => FilterListWidget(
        initalType: walletListViewModel.orderType,
        initalAscending: walletListViewModel.ascending,
        onClose: (ascending, type) async {
          walletListViewModel.setAscending(ascending);
          await walletListViewModel.setOrderType(type);
        },
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
  Flushbar<void>? _progressBar;
  bool _loadingWallet = false;

  WalletListViewModel get _viewModel => widget.walletListViewModel;

  @override
  Widget build(BuildContext context) => GradientBackground(
    scaffold: Container(
      height: double.infinity,
      padding: const EdgeInsets.only(top: 16),
      child: Stack(
        alignment: Alignment.bottomCenter,
        fit: StackFit.expand,
        children: [
          SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Observer(
              builder: (_) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_viewModel.multiWalletGroups.isNotEmpty) ...[
                    _SectionTitle(S.current.shared_seed_wallets),
                    _buildGroupList(),
                    const SizedBox(height: 24),
                  ],
                  if (_viewModel.singleWalletsList.isNotEmpty) ...[
                    _SectionTitle(S.current.single_seed_wallets_group),
                    _buildSingleWalletList(),
                  ],
                  const SizedBox(height: 250),
                ],
              ),
            ),
          ),
          _BottomActions(onRestore: _openRestore, onCreate: _openCreate),
        ],
      ),
    ),
  );

  Widget _buildGroupList() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: Observer(
      builder: (_) => FilteredList(
        shrinkWrap: true,
        list: _viewModel.multiWalletGroups,
        updateFunction: _viewModel.reorderAccordingToWalletList,
        itemBuilder: _buildGroupTile,
      ),
    ),
  );

  Widget _buildSingleWalletList() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: Observer(
      builder: (_) => FilteredList(
        shrinkWrap: true,
        list: _viewModel.singleWalletsList,
        updateFunction: _viewModel.reorderAccordingToWalletList,
        itemBuilder: _buildSingleWalletTile,
      ),
    ),
  );

  Widget _buildGroupTile(BuildContext context, int index) {
    final group = _viewModel.multiWalletGroups[index];
    final groupName = group.groupName ?? "${S.current.wallet_group} ${index + 1}";
    final isExpanded = _viewModel.expansionTileStateTrack[index] ?? false;

    return GroupedWalletExpansionTile(
      tileKey: ValueKey("group_wallets_expansion_tile_widget_$index"),
      title: groupName,
      borderRadius: _tileRadius,
      isSelected: false,
      shouldShowCurrentWalletPointer: true,
      onExpansionChanged: (value) => setState(() => _viewModel.updateTileState(index, value)),
      leadingWidget: CakeImageWidget(
        imageUrl: "assets/new-ui/navbar/wallets.svg",
        width: 28,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      trailingWidget: EditWalletButtonWidget(
        width: 88,
        isGroup: true,
        isExpanded: isExpanded,
        onTap: () => _openGroupEdit(group, groupName: groupName),
      ),
      childWallets: group.wallets.map(_viewModel.convertWalletInfoToWalletListItem).toList(),
      onChildItemTapped: _onWalletTapped,
      childTrailingWidget: (item) => item.isCurrent
          ? const SizedBox.shrink()
          : EditWalletButtonWidget(
        key: ValueKey("wallet_list_edit_${item.name}_button_key"),
        width: 64,
        onTap: () => _openWalletEdit(item),
      ),
    );
  }

  Widget _buildSingleWalletTile(BuildContext context, int index) {
    final wallet = _viewModel.singleWalletsList[index];
    final group = _viewModel.singleWalletGroupByWalletId[wallet.key];
    final title = group?.groupName ?? wallet.name;

    return GroupedWalletExpansionTile(
      tileKey: ValueKey('single_wallets_expansion_tile_widget_$index'),
      title: title,
      borderRadius: _tileRadius,
      margin: const EdgeInsets.only(left: 20, right: 20, bottom: 12),
      isSelected: false,
      isCurrentlySelectedWallet: wallet.isCurrent,
      leadingWidget: _SingleWalletLeading(wallet: wallet),
      onTitleTapped: () => _onWalletTapped(wallet),
      trailingWidget: group == null
          ? null
          : EditWalletButtonWidget(
        key: ValueKey("wallet_list_edit_${wallet.name}_button_key"),
        width: 64,
        onTap: () => _openGroupEdit(group, groupName: title, wallet: wallet),
      ),
    );
  }

  void _onWalletTapped(WalletListItem wallet) {
    if (!wallet.isCurrent) {
      _loadWallet(wallet);
    }
  }

  void _openGroupEdit(WalletGroup group, {required String groupName, WalletListItem? wallet}) =>
      Navigator.of(context).pushNamed(
        Routes.walletEdit,
        arguments: WalletEditPageArguments(
          walletListViewModel: _viewModel,
          editingWallet:
          wallet ?? _viewModel.convertWalletInfoToWalletListItem(group.wallets.first),
          isWalletGroup: true,
          isSingleWalletGroup: wallet != null,
          groupName: groupName,
          walletGroupKey: group.groupKey,
        ),
      );

  void _openWalletEdit(WalletListItem wallet) => Navigator.of(context).pushNamed(
    Routes.walletEdit,
    arguments: WalletEditPageArguments(
      walletListViewModel: _viewModel,
      editingWallet: wallet,
    ),
  );

  void _openRestore() => _pushWithCreation2FA(Routes.restoreOptions, arguments: false);

  void _openCreate() {
    if (isSingleCoin) {
      _pushWithCreation2FA(
        Routes.newWallet,
        arguments: NewWalletArguments(type: _viewModel.currentWalletType),
      );
    } else {
      _pushWithCreation2FA(Routes.newWalletType);
    }
  }

  void _pushWithCreation2FA(String route, {Object? arguments}) {
    final requires2FA = _viewModel.shouldRequireTOTP2FAForCreatingNewWallets;
    if (!requires2FA) {
      Navigator.of(context).pushNamed(route, arguments: arguments);
      return;
    }
    widget.authService.authenticateAction(
      context,
      route: route,
      arguments: arguments,
      conditionToDetermineIfToUse2FA: requires2FA,
    );
  }

  Future<void> _loadWallet(WalletListItem wallet) async {
    if (_loadingWallet) {
      printV("_loadWallet abandoned because _loadingWallet");
      return;
    }

    _loadingWallet = true;

    if (SettingsStoreBase.walletPasswordDirectInput) {
      Navigator.of(context).pushNamed(
        Routes.walletUnlockLoadable,
        arguments: WalletUnlockArguments(
          callback: (bool isAuthenticatedSuccessfully, AuthPageState auth) async {
            if (isAuthenticatedSuccessfully) {
              auth.close();
              setState(() {});
            }
          },
          walletName: wallet.name,
          walletType: wallet.type,
        ),
      );
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
          await _viewModel.requireHardwareWalletConnection(wallet);
          if (requireHardwareWalletConnection) {
            final didConnect = await _connectLedger();
            if (!didConnect) return;
          }

          changeProcessText(S.of(context).wallet_list_loading_wallet(wallet.name));
          await _viewModel.loadWallet(wallet);
          unawaited(hideProgressText());

          if (responsiveLayoutUtil.shouldRenderMobileUI) {
            if (!mounted || !context.mounted) return;
            if (requireHardwareWalletConnection) {
              Navigator.of(context).pop();
            }
            await widget.onWalletLoaded.call(context);
          }
        } catch (e) {
          await ExceptionHandler.resetLastPopupDate();
          await ExceptionHandler.onError(FlutterErrorDetails(exception: e.toString()));
          if (mounted) {
            changeProcessText(S.of(context).wallet_list_failed_to_load(wallet.name, e.toString()));
          }
        } finally {
          _loadingWallet = false;
        }
      },
      conditionToDetermineIfToUse2FA: _viewModel.shouldRequireTOTP2FAForAccessingWallet,
    );
    _loadingWallet = false;
  }

  Future<bool> _connectLedger() async {
    var didConnect = false;
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

    if (!didConnect || !mounted) return false;

    showPopUp<void>(
      context: context,
      builder: (BuildContext context) => AlertWithOneAction(
        alertTitle: S.of(context).proceed_on_device,
        alertContent: S.of(context).proceed_on_device_description,
        buttonText: S.of(context).cancel,
        alertBarrierDismissible: false,
        buttonAction: () => Navigator.of(context).pop(),
      ),
    );
    return true;
  }

  void changeProcessText(String text) {
    try {
      _progressBar?.dismiss();
      _progressBar = createBar<void>(text, context, duration: null)..show(context);
    } catch (_) {}
  }

  Future<void> hideProgressText() async {
    await Future.delayed(const Duration(milliseconds: 50), () {
      try {
        _progressBar?.dismiss();
        _progressBar = null;
      } catch (_) {}
    });
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 24, bottom: 16),
    child: Text(
      text,
      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    ),
  );
}

class _SingleWalletLeading extends StatelessWidget {
  const _SingleWalletLeading({required this.wallet});

  final WalletListItem wallet;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: wallet.isCurrent ? 56 : 40,
    child: Row(
      children: [
        wallet.isCurrent
            ? Container(
          height: 35,
          width: 6,
          margin: const EdgeInsets.only(right: 16),
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(18),
              bottomRight: Radius.circular(18),
            ),
            color: Theme.of(context).colorScheme.primary,
          ),
        )
            : const SizedBox(width: 6),
        CakeImageWidget(
          imageUrl: getCryptoCurrencyIconForWalletListItem(wallet.type),
          width: 32,
          height: 32,
        ),
      ],
    ),
  );
}

class _BottomActions extends StatelessWidget {
  const _BottomActions({required this.onRestore, required this.onCreate});

  final VoidCallback onRestore;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        IgnorePointer(
          child: Container(
            height: 275,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  colors.surfaceDim.withAlpha(10),
                  colors.surfaceDim.withAlpha(150),
                  for (var i = 0; i < 5; i++) colors.surfaceDim.withAlpha(255),
                ],
              ),
            ),
          ),
        ),
        Container(
          height: 240,
          width: MediaQuery.of(context).size.width,
          margin: const EdgeInsets.only(bottom: 24),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              PrimaryImageButton(
                key: const ValueKey("wallet_list_page_restore_wallet_button_key"),
                image: Image.asset(
                  "assets/images/restore_wallet.png",
                  height: 12,
                  width: 12,
                  color: colors.onSecondaryContainer,
                ),
                onPressed: onRestore,
                text: S.of(context).wallet_list_restore_wallet,
                color: colors.surfaceContainer,
                textColor: colors.onSecondaryContainer,
              ),
              const SizedBox(height: 10),
              PrimaryImageButton(
                key: const ValueKey("wallet_list_page_create_new_wallet_button_key"),
                image: Image.asset(
                  "assets/images/new_wallet.png",
                  height: 12,
                  width: 12,
                  color: colors.onPrimary,
                ),
                onPressed: onCreate,
                text: S.of(context).wallet_list_create_new_wallet,
                color: colors.primary,
                textColor: colors.onPrimary,
              ),
              const SizedBox(height: 52),
            ],
          ),
        ),
      ],
    );
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    label: "Transaction Filter",
    button: true,
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        height: 36,
        width: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Theme.of(context).colorScheme.surfaceContainer,
        ),
        child: Image.asset(
          "assets/images/filter_icon.png",
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    ),
  );
}
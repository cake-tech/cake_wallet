import 'package:cake_wallet/core/new_wallet_arguments.dart';
import 'package:cake_wallet/core/new_wallet_type_arguments.dart';
import 'package:cake_wallet/di.dart';
import 'dart:io';

import 'package:cake_wallet/core/new_wallet_arguments.dart';
import 'package:cake_wallet/core/new_wallet_type_arguments.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/reactions/wallet_utils.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/screens/new_wallet/widgets/select_button.dart';
import 'package:cake_wallet/src/screens/setup_2fa/widgets/popup_cancellable_alert.dart';
import 'package:cake_wallet/src/widgets/bottom_sheet/base_bottom_sheet_widget.dart';
import 'package:cake_wallet/src/widgets/bottom_sheet/info_bottom_sheet_widget.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/src/widgets/scollable_with_bottom_section.dart';
import 'package:cake_wallet/src/widgets/search_bar_widget.dart';
import 'package:cake_wallet/src/widgets/standard_checkbox.dart';
import 'package:cake_wallet/store/app_store.dart' show AppStore;
import 'package:cake_wallet/themes/core/material_base_theme.dart';
import 'package:cake_wallet/themes/utils/theme_list.dart';
import 'package:cake_wallet/utils/responsive_layout_util.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:cake_wallet/view_model/new_wallet_group_view_model.dart';
import 'package:cake_wallet/view_model/new_wallet_type_view_model.dart';
import 'package:cake_wallet/view_model/seed_settings_view_model.dart';
import 'package:cake_wallet/view_model/wallet_restore_view_model.dart';
import 'package:cake_wallet/wallet_types.g.dart';
import 'package:cw_core/currency_for_wallet_type.dart';
import 'package:cw_core/hardware/device_connection_type.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

class NewWalletTypePage extends BasePage {
  NewWalletTypePage({
    required this.newWalletTypeViewModel,
    required this.newWalletTypeArguments,
    required this.seedSettingsViewModel,
  });

  final NewWalletTypeViewModel newWalletTypeViewModel;
  final NewWalletTypeArguments newWalletTypeArguments;
  final SeedSettingsViewModel seedSettingsViewModel;

  final walletTypeImage = Image.asset('assets/images/wallet_type.png');
  final walletTypeLightImage =
      Image.asset('assets/images/wallet_type_light.png');

  @override
  String get title => newWalletTypeArguments.isCreate
      ? S.current.wallet_list_create_new_wallet
      : S.current.wallet_list_restore_wallet;

  @override
  Function(BuildContext)? get pushToNextWidget => (context) {
        FocusScopeNode currentFocus = FocusScope.of(context);
        if (!currentFocus.hasPrimaryFocus) {
          currentFocus.focusedChild?.unfocus();
        }
      };

  @override
  Widget body(BuildContext context) => WalletTypeForm(
      walletImage: currentTheme.isDark ? walletTypeImage : walletTypeLightImage,
      isCreate: newWalletTypeArguments.isCreate,
      newWalletTypeViewModel: newWalletTypeViewModel,
      seedSettingsViewModel: seedSettingsViewModel,
      onTypeSelected: newWalletTypeArguments.onTypeSelected,
      allowMultiSelect: newWalletTypeArguments.allowMultiSelect,
      constrainBip39Only: newWalletTypeArguments.constrainBip39Only,
      preselectedTypes: newWalletTypeArguments.preselectedTypes,
      credentials: newWalletTypeArguments.credentials,
  hardwareWalletType: newWalletTypeArguments.hardwareWalletType,
      currentTheme: currentTheme);
}

class WalletTypeForm extends StatefulWidget {
  WalletTypeForm(
      {required this.walletImage,
      required this.isCreate,
      required this.newWalletTypeViewModel,
      required this.seedSettingsViewModel,
      this.onTypeSelected,
      this.hardwareWalletType,
      this.allowMultiSelect = false,
      this.constrainBip39Only = false,
      this.preselectedTypes,
      this.credentials,
      required this.currentTheme})
      : filteredAvailableWalletTypes = constrainBip39Only
            ? availableWalletTypes
                .where((type) =>
                    isBIP39Wallet(type) &&
                    (!(preselectedTypes?.contains(type) ?? true)))
                .toList()
            : availableWalletTypes;

  final bool isCreate;
  final Image walletImage;
  final NewWalletTypeViewModel newWalletTypeViewModel;
  final SeedSettingsViewModel seedSettingsViewModel;
  final void Function(BuildContext, WalletType)? onTypeSelected;
  final bool allowMultiSelect;
  final bool constrainBip39Only;
  final Set<WalletType>? preselectedTypes;
  final List<WalletType> filteredAvailableWalletTypes;
  final Object? credentials;
  final MaterialThemeBase currentTheme;
  final HardwareWalletType? hardwareWalletType;
  bool get isHardwareWallet => hardwareWalletType != null;


  @override
  WalletTypeFormState createState() => WalletTypeFormState();
}

class WalletTypeFormState extends State<WalletTypeForm> {
  WalletTypeFormState();

  static const aspectRatioImage = 1.22;

  final TextEditingController searchController = TextEditingController();

  List<WalletType> types = [];
  List<WalletType> filteredTypes = [];

  @override
  void initState() {
    types = filteredTypes = widget.filteredAvailableWalletTypes
        .where((element) =>
            !widget.isHardwareWallet ||
            DeviceConnectionType.supportedConnectionTypes(
                    element, widget.hardwareWalletType!, Platform.isIOS)
                .isNotEmpty)
        .toList();

    super.initState();

    searchController.addListener(() {
      setState(() {
        filteredTypes = List.from(types.where((type) =>
            walletTypeToDisplayName(type)
                .toLowerCase()
                .contains(searchController.text.toLowerCase())));
        return;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = widget.newWalletTypeViewModel;
    final preselectedTypes = widget.preselectedTypes;
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
            maxWidth: ResponsiveLayoutUtilBase.kDesktopMaxWidthConstraint),
        child: Column(
          children: [
            preselectedTypes != null && preselectedTypes.isNotEmpty
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(top: 18),
                        child: Text(
                          'Want to create more wallets for this wallet group? Feel free to do so below (or anytime later in the Wallets page).',
                          textAlign: TextAlign.center,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                        ),
                      ),
                      SizedBox(height: 12),
                      InkWell(
                        onTap: () => showInfoBottomSheet(widget.currentTheme),
                        child: Text(
                          'What is a wallet group?',
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                      )
                    ],
                  )
                : Padding(
                    padding: EdgeInsets.only(top: 48),
                    child: Text(
                      S.of(context).choose_wallet_currency,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ),
            Padding(
              padding: EdgeInsets.fromLTRB(24, 24, 24, 12),
              child: SearchBarWidget(searchController: searchController),
            ),
            Expanded(
              child: ScrollableWithBottomSection(
                  contentPadding:
                      EdgeInsets.only(left: 24, right: 24, bottom: 24),
                  scrollableKey: ValueKey('new_wallet_type_scrollable_key'),
                  content: Observer(
                    builder: (_) => Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        ...filteredTypes.map(
                          (type) => Padding(
                            padding: EdgeInsets.only(top: 12),
                            child: SelectButton(
                              key: ValueKey(
                                  'new_wallet_type_${type.name}_button_key'),
                              padding: EdgeInsets.only(left: 12, right: 30),
                              leading: widget.isCreate
                                  ? Padding(
                                      padding: const EdgeInsets.only(right: 12),
                                      child: StandardCheckbox(
                                        value: viewModel.itemSelection[type] ??
                                            false,
                                        caption: '',
                                        onChanged: (_) =>
                                            viewModel.toggleSelection(type),
                                      ),
                                    )
                                  : null,
                              image: Image.asset(
                                walletTypeToCryptoCurrency(type).iconPath ?? '',
                                height: 24,
                                width: 24,
                              ),
                              text: walletTypeToDisplayName(type),
                              showTrailingIcon: false,
                              height: 54,
                              isSelected: widget.isCreate
                                  ? false
                                  : (viewModel.itemSelection[type] ?? false),
                              onTap: () {
                                if (widget.isCreate) {
                                  viewModel.toggleSelection(type);
                                } else {
                                  // In restore flow, only single selection is allowed
                                  for (var item in types) {
                                    if (item == type) {
                                      viewModel.itemSelection[item] = true;
                                    } else {
                                      viewModel.itemSelection[item] = false;
                                    }
                                  }
                                }
                              },
    deviceConnectionTypes: widget.isHardwareWallet
    ? DeviceConnectionType.supportedConnectionTypes(
    type, widget.hardwareWalletType!, Platform.isIOS)
        : [],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  bottomSectionPadding:
                      EdgeInsets.only(left: 24, right: 24, bottom: 24),
                  bottomSection: Column(
                    children: [
                      if (preselectedTypes != null && preselectedTypes.length == 1)
                        Observer(
                          builder: (_) => PrimaryButton(
                            key: ValueKey('skip_wallet_type_next_button_key'),
                            onPressed: () => onSkipSelect(),
                            text: 'Skip',
                            color:
                                Theme.of(context).colorScheme.surfaceContainer,
                            textColor: Theme.of(context)
                                .colorScheme
                                .onSecondaryContainer,
                            isDisabled: viewModel.hasAnySelected,
                          ),
                        ),
                      SizedBox(height: 10),
                      Observer(
                        builder: (_) => PrimaryButton(
                          key: ValueKey('new_wallet_type_next_button_key'),
                          onPressed: () => onTypeSelected(),
                          text: S.of(context).seed_language_next,
                          color: Theme.of(context).colorScheme.primary,
                          textColor: Theme.of(context).colorScheme.onPrimary,
                          isDisabled: !viewModel.hasAnySelected,
                        ),
                      ),
                    ],
                  )),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> onSkipSelect() async {
    // Single-wallet restoration flow

    try {

    if (widget.preselectedTypes != null &&
        widget.preselectedTypes!.length == 1) {

      final type = widget.preselectedTypes!.first;

      final credentials = (widget.credentials != null && widget.credentials is Map<String, dynamic>)
          ? (widget.credentials as Map<String, dynamic>)
          : null;
      if (credentials == null) return;

      final walletRestoreViewModel = getIt.get<WalletRestoreViewModel>(param1: type, param2: null);

      await walletRestoreViewModel.create(options: credentials);

      widget.seedSettingsViewModel.setPassphrase(null);


    }
  } catch (e) {
      await showPopUp<void>(
        context: context,
        builder: (BuildContext context) => PopUpCancellableAlertDialog(
          contentText: e.toString(),
          actionButtonText: S.of(context).ok,
          buttonAction: () => Navigator.of(context).pop(),
        ),
      );
    }
  }

  Future<void> onTypeSelected() async {
    final viewModel = widget.newWalletTypeViewModel;

    final mergedTypes = <WalletType>[
      ...?widget.preselectedTypes,
      ...viewModel.selectedTypes,
    ];

    try {
      if (mergedTypes.isEmpty) {
        throw Exception('Wallet Type is not selected yet.');
      }

      // Creation flow
      if (widget.isCreate) {
        // Haven wallet creation alert
        if (mergedTypes.contains(WalletType.haven)) {
          throw Exception(S.of(context).pause_wallet_creation);
        }

        // Single-wallet creation flow
        if (mergedTypes.length == 1) {
          final selected = mergedTypes.first;

          // Not a BIP39 wallet or no existing wallet, go to new wallet creation flow
          if (!isBIP39Wallet(selected) || !viewModel.hasExisitingWallet) {
            Navigator.of(context).pushNamed(
              Routes.newWallet,
              arguments: NewWalletArguments(type: selected),
            );
          } else {
            // BIP39 wallet and existing wallet, go to pre-existing seed flow
            Navigator.of(context)
                .pushNamed(Routes.walletGroupDescription, arguments: selected);
          }
          return;
        }

        // Multi-wallet creation flow
        if (mergedTypes.length > 1) {
          if (!onlyBIP39Selected(mergedTypes)) {
            throw Exception('Multi-wallet creation supports only BIP39 wallet types.');
          }

          // If there are preselected types, it means we’re adding to an existing group
          if (widget.preselectedTypes != null && widget.preselectedTypes!.isNotEmpty) {
            // 1) Figure out which type is already existing (pick the first preselected)
            final existingType = widget.preselectedTypes!.first;

            // 2) The rest are the ones we want to add now
            final toAdd = mergedTypes.where((t) => t != existingType).toList();
            if (toAdd.isEmpty) return;

            // 3) Resolve the shared mnemonic (prefer passed-in credentials; otherwise from current wallet)
            Map<String, dynamic>? creds;
            try {
              final dynCreds = (widget as dynamic).credentials;
              if (dynCreds is Map<String, dynamic>) {
                creds = dynCreds;
              }
            } catch (_) {
              // ignore – creds stays null
            }

            final sharedMnemonic = (creds?['seed'] as String?)?.trim().isNotEmpty == true
                ? (creds!['seed'] as String).trim()
                : getIt.get<AppStore>().wallet?.seed;

            if (sharedMnemonic == null || sharedMnemonic.isEmpty) {
              throw Exception('Shared mnemonic is missing.');
            }

            // 4) Get the current wallet’s group key (existing wallet must be current)
            final groupKey = getIt
                .get<AppStore>()
                .wallet
                ?.walletInfo
                .hashedWalletIdentifier ??
                '';
            if (groupKey.isEmpty) {
              throw Exception('Could not resolve group key from the current wallet.');
            }

            // 5) Build a temporary VM and call createRestWallets
            final allTypes = <WalletType>{...widget.preselectedTypes!, ...mergedTypes}.toList();
            final args = WalletGroupArguments(
              types: allTypes,
              currentType: existingType,
              mnemonic: sharedMnemonic, // VM can reuse this instead of reading from first wallet
            );

            final groupVM = getIt<WalletGroupNewVM>(param1: args);

            await groupVM.createRestWallets(
              WalletGroupParams(
                restTypes: toAdd,
                sharedMnemonic: sharedMnemonic,
                isChildWallet: true,
                groupKey: groupKey,
              ),
            );

            if (context.mounted) {
              Navigator.of(context).pop();
            }
            return;
          }

          // Otherwise: pure multi-wallet creation flow (no existing group yet)
          final arguments = WalletGroupArguments(
            types: mergedTypes,
            currentType: mergedTypes.first,
          );
          Navigator.of(context).pushNamed(Routes.newWalletGroup, arguments: arguments);
          return;
        }

        return; // safety (shouldn’t reach here)
      }

      // Restoration flow (single selection expected here)
      if (!widget.isCreate) {
        widget.onTypeSelected!(context, mergedTypes.first);
        return;
      }
    } catch (e) {
      await showPopUp<void>(
        context: context,
        builder: (BuildContext context) => PopUpCancellableAlertDialog(
          contentText: e.toString(),
          actionButtonText: S.of(context).ok,
          buttonAction: () => Navigator.of(context).pop(),
        ),
      );
    }
  }

  Future<void> showInfoBottomSheet(MaterialThemeBase currentTheme) async {
    await showModalBottomSheet<void>(
      context: context,
      scrollControlDisabledMaxHeightRatio: 0.7,
      isDismissible: false,
      builder: (BuildContext bottomSheetContext) => InfoBottomSheet(
        footerType: FooterType.singleActionButton,
        height: 500,
        titleText: '',
        contentImage: currentTheme == ThemeList.lightTheme
            ? 'assets/images/wallet_group_options_light.png'
            : 'assets/images/wallet_group_options_dark.png',
        contentImageSize: 200,
        bottomTextWidget: Padding(
          padding: EdgeInsets.fromLTRB(24, 24, 24, 0),
          child: Text(
            'In Cake Wallet, you can create a wallet group by selecting an existing wallet to share a seed with. Each wallet group can contain a single wallet of each currency type. \n\n'
            'You can select Choose Wallet Group to see the available wallets and/or wallet groups screen.Or choose Create New Seed to create a wallet with an entirely new seed.',
            style: TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),
        singleActionButtonText: S.of(bottomSheetContext).litecoin_mweb_dismiss,
        singleActionButtonKey: ValueKey('send_page_sent_dialog_ok_button_key'),
        onSingleActionButtonPressed: () =>
            Navigator.of(bottomSheetContext).pop(),
      ),
    );
  }
}

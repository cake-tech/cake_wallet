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
import 'package:cake_wallet/src/widgets/alert_with_one_action.dart';
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
import 'package:cw_core/wallet_base.dart';
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
      : newWalletTypeArguments.preselectedTypes.isNotEmpty
          ? S.current.select_currency
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
      inGroup: newWalletTypeArguments.inGroup,
      newWalletTypeViewModel: newWalletTypeViewModel,
      seedSettingsViewModel: seedSettingsViewModel,
      onTypeSelected: newWalletTypeArguments.onTypeSelected,
      preselectedTypes: newWalletTypeArguments.preselectedTypes,
      credentials: newWalletTypeArguments.credentials,
      hardwareWalletType: newWalletTypeArguments.hardwareWalletType,
      walletGroupKey: newWalletTypeArguments.walletGroupKey,
      currentTheme: currentTheme);
}

class WalletTypeForm extends StatefulWidget {
  WalletTypeForm(
      {required this.walletImage,
      required this.isCreate,
      required this.inGroup,
      required this.newWalletTypeViewModel,
      required this.seedSettingsViewModel,
      this.onTypeSelected,
      this.hardwareWalletType,
      this.preselectedTypes,
      this.credentials,
      this.walletGroupKey,
      required this.currentTheme})
      : filteredAvailableWalletTypes = inGroup
            ? availableWalletTypes
                .where((type) =>
                    isBIP39Wallet(type) &&
                    (!(preselectedTypes?.contains(type) ?? true)))
                .toList()
            : availableWalletTypes;

  final bool isCreate;
  final bool inGroup;
  final Image walletImage;
  final NewWalletTypeViewModel newWalletTypeViewModel;
  final SeedSettingsViewModel seedSettingsViewModel;
  final void Function(BuildContext, WalletType)? onTypeSelected;
  final Set<WalletType>? preselectedTypes;
  final List<WalletType> filteredAvailableWalletTypes;
  final Object? credentials;
  final MaterialThemeBase currentTheme;
  final HardwareWalletType? hardwareWalletType;
  final String? walletGroupKey;

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

  bool _isProcessing = false;

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


  bool isSelected(WalletType type) => widget.inGroup
      ? false
      : (widget.newWalletTypeViewModel.itemSelection[type] ?? false);

  void onTypeTap(WalletType type) {
    if (widget.inGroup) {
      widget.newWalletTypeViewModel.deselectAllNonBIP39();
      widget.newWalletTypeViewModel.toggleSelection(type);
    } else {
      widget.newWalletTypeViewModel.deselectAll();
      for (var item in types) {
        if (item == type) {
          widget.newWalletTypeViewModel.itemSelection[item] = true;
        }
      }
    }
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
                          S.of(context).want_to_create_more_wallets,
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
                          S.of(context).What_is_a_wallet_group,
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
                              leading: widget.inGroup
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
                              isSelected: isSelected(type),
                              onTap: () => onTypeTap(type),
                              deviceConnectionTypes: widget.isHardwareWallet
                                  ? DeviceConnectionType
                                      .supportedConnectionTypes(
                                          type,
                                          widget.hardwareWalletType!,
                                          Platform.isIOS)
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
                      if (preselectedTypes != null &&
                          preselectedTypes.length == 1)
                        Observer(
                          builder: (_) => PrimaryButton(
                            key: ValueKey('skip_wallet_type_next_button_key'),
                            onPressed: () => onSkipSelect(),
                            text: S.of(context).skip,
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
                        builder: (_) => LoadingPrimaryButton(
                          key: ValueKey('new_wallet_type_next_button_key'),
                          onPressed: () => onTypeSelected(),
                          text: S.of(context).seed_language_next,
                          color: Theme.of(context).colorScheme.primary,
                          textColor: Theme.of(context).colorScheme.onPrimary,
                          isLoading: _isProcessing,
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

        final credentials = (widget.credentials != null &&
                widget.credentials is Map<String, dynamic>)
            ? (widget.credentials as Map<String, dynamic>)
            : null;
        if (credentials == null) return;

        final walletRestoreViewModel =
            getIt.get<WalletRestoreViewModel>(param1: type, param2: null);

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
      if (mounted) setState(() => _isProcessing = true);

      if (mergedTypes.isEmpty) {
        throw Exception('Wallet Type is not selected yet.');
      }

      // Creation flow
      if (widget.isCreate) {
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
            throw Exception(
                'Multi-wallet creation supports only BIP39 wallet types.');
          }

          // Adding wallets to an existing wallet group via explicit group key
          if (widget.walletGroupKey != null &&
              widget.walletGroupKey!.isNotEmpty) {
            final groupKey = widget.walletGroupKey!;
            final current = viewModel.appStore.wallet;
            if (current == null) {
              throw Exception('No wallet is currently opened.');
            }

            // Ensure current wallet belongs to the same group so we can reuse its seed
            final sameGroup =
                current.walletInfo.hashedWalletIdentifier == groupKey;
            if (sameGroup != true) {
              throw Exception(
                  'Please open a wallet from this group first before adding new wallets to it.');
            }

            await _createRestWalletsInGroup(
              context: context,
              groupKey: groupKey,
              current: current,
              allSelectedTypes: mergedTypes,
              alreadyInGroup: widget.preselectedTypes ?? const <WalletType>{},
              viewModel: viewModel,
            );

            if (mounted) setState(() => _isProcessing = false);
            if (context.mounted) Navigator.of(context).pop();
            return;
          }

          // Pure multi-wallet creation flow
          final arguments = WalletGroupArguments(
            types: mergedTypes,
            currentType: mergedTypes.first,
          );
          Navigator.of(context)
              .pushNamed(Routes.newWalletGroup, arguments: arguments);
          return;
        }

        return;
      }

      // Restoration flow
      if (!widget.isCreate) {
        // Single-wallet restoration flow
        if (mergedTypes.length == 1) {
          widget.onTypeSelected!(context, mergedTypes.first);
          return;
        }

        // Multi-wallet BIP39 restoration flow
        if (mergedTypes.length > 1 && onlyBIP39Selected(mergedTypes)) {
          if (widget.preselectedTypes == null ||
              widget.preselectedTypes!.isEmpty) {
            throw Exception('Original wallet type is not provided.');
          }
          final originalType = widget.preselectedTypes!.first;

          // 1) Restore the original wallet first
          final Map<String, dynamic>? credentials =
              switch (widget.credentials) {
            Map<String, dynamic> map => map,
            _ => null,
          };

          final originalVM = getIt.get<WalletRestoreViewModel>(
              param1: originalType, param2: null);
          await originalVM.create(options: credentials);

          // 2) After restore, the new wallet is current. Reuse its seed + groupKey (no seed in credentials).
          final current = viewModel.appStore.wallet;
          if (current == null)
            throw Exception('Failed to open the restored wallet.');

          final groupKey = current.walletInfo.hashedWalletIdentifier ?? '';
          if (groupKey.isEmpty)
            throw Exception(
                'Could not resolve group key from the restored wallet.');

          await _createRestWalletsInGroup(
            context: context,
            groupKey: groupKey,
            current: current,
            allSelectedTypes: mergedTypes,
            alreadyInGroup: widget.preselectedTypes ?? {},
            viewModel: viewModel,
          );

          if (context.mounted) {
            Navigator.of(context)
                .pushNamedAndRemoveUntil(Routes.dashboard, (route) => false);
          }
          return;
        }

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
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _createRestWalletsInGroup({
    required BuildContext context,
    required String groupKey,
    required WalletBase current,
    required List<WalletType> allSelectedTypes,
    required Set<WalletType> alreadyInGroup,
    required NewWalletTypeViewModel viewModel,
  }) async {
    final sharedMnemonic = current.seed ?? '';
    final sharedPassphrase = current.passphrase ?? '';

    if (sharedMnemonic.isEmpty) {
      throw Exception(
          'Shared mnemonic is unavailable from the current wallet.');
    }

    final rawToAdd =
        allSelectedTypes.where((t) => !alreadyInGroup.contains(t)).toList();

    final excluded = <WalletType>[];
    final toAdd = <WalletType>[];

    for (final type in rawToAdd) {
      final passphraseUnsupported = !viewModel.isPassPhraseSupported(type);
      if (passphraseUnsupported && sharedPassphrase.isNotEmpty) {
        excluded.add(type);
      } else {
        toAdd.add(type);
      }
    }

    if (excluded.isNotEmpty) {
      await showPopUp<void>(
        context: context,
        builder: (dialogCtx) => AlertWithOneAction(
          key:
              const ValueKey('new_wallet_group_page_excluded_types_dialog_key'),
          buttonKey: const ValueKey(
              'new_wallet_group_page_excluded_types_dialog_button_key'),
          alertTitle: S.current.alert_notice,
          alertContent:
              'The following wallet types cannot be added because they do not support passphrase protection\n'
              '${excluded.map((e) => walletTypeToDisplayName(e)).join(', ')}',
          buttonText: S.of(dialogCtx).ok,
          buttonAction: () => Navigator.of(dialogCtx).pop(),
        ),
      );
    }

    if (toAdd.isEmpty) {
      return;
    }

    final existingType = alreadyInGroup.isNotEmpty
        ? alreadyInGroup.first
        : allSelectedTypes.first;

    final args = WalletGroupArguments(
      types: <WalletType>{...alreadyInGroup, ...allSelectedTypes}.toList(),
      currentType: existingType,
      mnemonic: sharedMnemonic, // reuse the same BIP-39 seed
    );

    final groupVM = getIt<WalletGroupNewVM>(param1: args);

    await groupVM.createRestWallets(
      WalletGroupParams(
        restTypes: toAdd,
        sharedMnemonic: sharedMnemonic,
        sharedPassphrase: sharedPassphrase,
        isChildWallet: true,
        groupKey: groupKey,
      ),
    );
  }

  Future<void> showInfoBottomSheet(MaterialThemeBase currentTheme) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext bottomSheetContext) {
        return WalletGroupInfoBottomSheet(currentTheme: currentTheme);
      },
    );
  }
}

class WalletGroupInfoBottomSheet extends StatelessWidget {
  const WalletGroupInfoBottomSheet({
    super.key,
    required this.currentTheme,
  });

  final MaterialThemeBase currentTheme;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final imagePath = currentTheme == ThemeList.lightTheme
        ? 'assets/images/wallet_group_options_light.png'
        : 'assets/images/wallet_group_options_dark.png';

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.7,
      builder: (context, scrollController) {
        return ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
          child: Container(
            color: theme.colorScheme.surface,
            child: Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 64,
                  height: 5,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: theme.colorScheme.onSurface.withOpacity(0.4),
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    child: Column(
                      children: [
                        Image.asset(
                          imagePath,
                          height: 200,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          S.of(context).wallet_group_description_bottom_sheet,
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
                SafeArea(
                  top: false,
                  minimum: const EdgeInsets.fromLTRB(30, 12, 30, 24),
                  child: SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: PrimaryButton(
                        key: ValueKey(
                            'wallet_group_info_bottom_sheet_dismiss_button_key'),
                        text: S.of(context).litecoin_mweb_dismiss,
                        onPressed: () => Navigator.of(context).pop(),
                        color: Theme.of(context).colorScheme.primary,
                        textColor: Theme.of(context).colorScheme.onPrimary,
                      )),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

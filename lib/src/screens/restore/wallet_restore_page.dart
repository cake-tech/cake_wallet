import "package:cake_wallet/core/execution_state.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/viewmodels/restore_wallet/seed_settings_cubit.dart";
import "package:cake_wallet/new-ui/viewmodels/restore_wallet/wallet_restore_cubit.dart";
import "package:cake_wallet/routes.dart";
import "package:cake_wallet/src/screens/base_page.dart";
import "package:cake_wallet/src/screens/restore/wallet_restore_from_keys_form.dart";
import "package:cake_wallet/src/screens/restore/wallet_restore_from_seed_form.dart";
import "package:cake_wallet/src/widgets/alert_with_one_action.dart";
import "package:cake_wallet/src/widgets/bottom_sheet/add_passphrase_bottom_sheet_widget.dart";
import "package:cake_wallet/src/widgets/keyboard_done_button.dart";
import "package:cake_wallet/src/widgets/primary_button.dart";
import "package:cake_wallet/src/widgets/standard_checkbox.dart";
import "package:cake_wallet/utils/show_pop_up.dart";
import "package:cake_wallet/view_model/restore/restore_mode.dart";
import "package:cake_wallet/zano/zano.dart";
import "package:cw_core/wallet_info.dart";
import "package:cw_core/wallet_type.dart";
import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:keyboard_actions/keyboard_actions.dart";

class WalletRestorePage extends BasePage {
  WalletRestorePage();

  @override
  Widget middle(BuildContext context) =>
      BlocSelector<WalletRestoreCubit, WalletRestoreState, WalletRestoreMode>(
        selector: (state) => state.mode,
        builder: (context, mode) => Text(
          mode == WalletRestoreMode.seed
              ? S.current.restore_title_from_seed
              : S.current.restore_title_from_keys,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
        ),
      );

  @override
  Function(BuildContext)? get popWidget =>
      (context) => context.read<SeedSettingsCubit>().setPassphrase(null);

  @override
  Function(BuildContext)? get pushToNextWidget => (context) {
        final currentFocus = FocusScope.of(context);
        if (!currentFocus.hasPrimaryFocus) {
          currentFocus.focusedChild?.unfocus();
        }
      };

  @override
  Widget body(BuildContext context) => const _WalletRestoreBody();
}

class _WalletRestoreBody extends StatefulWidget {
  const _WalletRestoreBody();

  @override
  State<_WalletRestoreBody> createState() => _WalletRestoreBodyState();
}

class _WalletRestoreBodyState extends State<_WalletRestoreBody>
    with SingleTickerProviderStateMixin {
  static const _scanDerivationPaths = {
    "m/84'/0'/0'",
    "m/86'/0'/0'",
    "m/44'/0'/0'",
    "m/49'/0'/0'",
  };

  final _seedFormKey = GlobalKey<WalletRestoreFromSeedFormState>();
  final _keysFormKey = GlobalKey<WalletRestoreFromKeysFormState>();
  final _blockHeightFocusNode = FocusNode();

  late final WalletRestoreCubit _cubit;
  late final SeedSettingsCubit _seedSettingsCubit;
  late final bool _hasKeysTab;
  late final TabController _tabController;

  bool _isFormProcessing = false;
  DerivationInfo? _derivationInfo;

  @override
  void initState() {
    super.initState();
    _cubit = context.read<WalletRestoreCubit>();
    _seedSettingsCubit = context.read<SeedSettingsCubit>();
    _hasKeysTab = _cubit.availableModes.contains(WalletRestoreMode.keys);

    final initialIndex = _cubit.state.mode == WalletRestoreMode.keys && _hasKeysTab ? 1 : 0;
    _tabController = TabController(
      length: _hasKeysTab ? 2 : 1,
      vsync: this,
      initialIndex: initialIndex,
    );
    _tabController.addListener(_onTabChanged);
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _blockHeightFocusNode.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      _cubit.setMode(_tabController.index == 0 ? WalletRestoreMode.seed : WalletRestoreMode.keys);
    }
  }

  void _onModeChanged(WalletRestoreMode mode) {
    final index = mode == WalletRestoreMode.seed ? 0 : 1;
    if (_tabController.index != index && index < _tabController.length) {
      _tabController.animateTo(index);
    }
    _clearFormControllers();
  }

  void _clearFormControllers() {
    final seedForm = _seedFormKey.currentState;
    seedForm?.blockchainHeightKey.currentState?.restoreHeightController.text = "";
    seedForm?.blockchainHeightKey.currentState?.dateController.text = "";
    seedForm?.nameTextEditingController.text = "";

    final keysForm = _keysFormKey.currentState;
    keysForm?.blockchainHeightKey.currentState?.restoreHeightController.text = "";
    keysForm?.blockchainHeightKey.currentState?.dateController.text = "";
    keysForm?.nameTextEditingController.text = "";
  }

  void _showRestoreError(String error) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      showPopUp<void>(
        context: context,
        builder: (dialogContext) => AlertWithOneAction(
          alertTitle: S.current.new_wallet,
          alertContent: error,
          buttonText: S.of(dialogContext).ok,
          buttonAction: () => Navigator.of(dialogContext).pop(),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) => KeyboardActions(
        config: KeyboardActionsConfig(
          keyboardActionsPlatform: KeyboardActionsPlatform.IOS,
          keyboardBarColor: Theme.of(context).colorScheme.surface,
          nextFocus: false,
          actions: [
            KeyboardActionsItem(
              focusNode: _blockHeightFocusNode,
              toolbarButtons: [(_) => KeyboardDoneButton()],
            ),
          ],
        ),
        child: Container(
          height: 0,
          color: Theme.of(context).colorScheme.surface,
          child: Center(
            child: Column(
              children: [
                Expanded(child: _buildTabs(context)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      _buildHasPassphraseCheckbox(),
                      const SizedBox(height: 16),
                      PrimaryButton(
                        key: const ValueKey("wallet_restore_advanced_settings_button_key"),
                        onPressed: _openAdvancedSettings,
                        text: S.of(context).advanced_settings,
                        color: Theme.of(context).colorScheme.surfaceContainer,
                        textColor: Theme.of(context).colorScheme.onSecondaryContainer,
                      ),
                      const SizedBox(height: 8),
                      _buildRestoreButton(),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );

  Widget _buildTabs(BuildContext context) => MultiBlocListener(
        listeners: [
          BlocListener<WalletRestoreCubit, WalletRestoreState>(
            listenWhen: (previous, current) => previous.mode != current.mode,
            listener: (_, state) => _onModeChanged(state.mode),
          ),
          BlocListener<WalletRestoreCubit, WalletRestoreState>(
            listenWhen: (previous, current) =>
                current.executionState is FailureState &&
                previous.executionState != current.executionState,
            listener: (_, state) => _showRestoreError((state.executionState as FailureState).error),
          ),
        ],
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: TabBar(
                controller: _tabController,
                splashFactory: NoSplash.splashFactory,
                indicatorSize: TabBarIndicatorSize.label,
                isScrollable: true,
                labelStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                unselectedLabelStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
                    ),
                labelColor: Theme.of(context).colorScheme.primary,
                indicatorColor: Theme.of(context).colorScheme.primary,
                indicatorPadding: EdgeInsets.zero,
                labelPadding: const EdgeInsets.only(right: 24),
                tabAlignment: TabAlignment.start,
                dividerColor: Colors.transparent,
                padding: EdgeInsets.zero,
                tabs: [
                  Tab(text: S.of(context).widgets_seed),
                  if (_hasKeysTab) Tab(text: S.of(context).keys),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  SingleChildScrollView(child: _buildSeedForm()),
                  if (_hasKeysTab) SingleChildScrollView(child: _buildKeysForm()),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _buildHasPassphraseCheckbox() => BlocBuilder<WalletRestoreCubit, WalletRestoreState>(
        buildWhen: (previous, current) =>
            previous.passphraseAvailable != current.passphraseAvailable ||
            previous.hasPassphrase != current.hasPassphrase,
        builder: (context, state) {
          if (!state.passphraseAvailable) {
            return const SizedBox.shrink();
          }
          return StandardCheckbox(
            key: const ValueKey("wallet_restore_has_passphrase_checkbox_key"),
            captionColor: Theme.of(context).colorScheme.onSecondaryContainer,
            value: state.hasPassphrase,
            caption: S.of(context).wallet_has_passphrase,
            onChanged: _cubit.setHasPassphrase,
          );
        },
      );

  Widget _buildRestoreButton() => BlocBuilder<WalletRestoreCubit, WalletRestoreState>(
        buildWhen: (previous, current) =>
            previous.hasPassphrase != current.hasPassphrase ||
            previous.isButtonEnabled != current.isButtonEnabled ||
            previous.isExecuting != current.isExecuting,
        builder: (context, state) => LoadingPrimaryButton(
          key: const ValueKey("wallet_restore_seed_or_key_restore_button_key"),
          onPressed: _onRestorePressed,
          text: state.hasPassphrase ? S.of(context).add_passphrase : S.of(context).restore_recover,
          color: Theme.of(context).colorScheme.primary,
          textColor: Theme.of(context).colorScheme.onPrimary,
          isLoading: state.isExecuting,
          isDisabled: !state.isButtonEnabled,
        ),
      );

  void _openAdvancedSettings() => Navigator.of(context).pushNamed(
        Routes.advancedPrivacySettings,
        arguments: {
          "isFromRestore": true,
          "type": _cubit.type,
          "useTestnet": _cubit.state.useTestnet,
          "toggleTestnet": _cubit.toggleUseTestnet,
          "zcashNetwork": _cubit.state.zcashNetwork,
          "setZcashNetwork": _cubit.setZcashNetwork,
        },
      );

  Future<void> _onRestorePressed() async {
    if (!_cubit.state.hasPassphrase) {
      await _confirmForm();
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isDismissible: false,
      isScrollControlled: true,
      builder: (bottomSheetContext) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(bottomSheetContext).viewInsets.bottom),
        child: AddPassphraseBottomSheet(
          titleText: S.of(bottomSheetContext).add_passphrase,
          onRestoreButtonPressed: (passphrase) async {
            _seedSettingsCubit.setPassphrase(passphrase);
            await _confirmForm();
          },
        ),
      ),
    );
  }

  WalletRestoreFromSeedForm _buildSeedForm() => WalletRestoreFromSeedForm(
        key: _seedFormKey,
        restoredWallet: _cubit.restoredWallet,
        seedSettingsCubit: _seedSettingsCubit,
        displayBlockHeightSelector: _cubit.hasBlockchainHeightSelector,
        displayLanguageSelector: _cubit.hasSeedLanguageSelector,
        type: _cubit.type,
        blockHeightFocusNode: _blockHeightFocusNode,
        onHeightOrDateEntered: (value) {
          if (_isValidSeed()) {
            _cubit.setButtonEnabled(value);
          }
        },
        onSeedChange: (seed) => _validateOnChange(isPolyseed: _cubit.isPolyseed(seed)),
        onLanguageChange: (language) =>
            _validateOnChange(isPolyseed: language.startsWith("POLYSEED_")),
        displayWalletPassword: _cubit.hasWalletPassword,
        onPasswordChange: _cubit.setWalletPassword,
        onRepeatedPasswordChange: _cubit.setRepeatedWalletPassword,
      );

  WalletRestoreFromKeysForm _buildKeysForm() => WalletRestoreFromKeysForm(
        key: _keysFormKey,
        restoredWallet: _cubit.restoredWallet,
        walletRestoreCubit: _cubit,
        displayPrivateKeyField: _cubit.hasRestoreFromPrivateKey,
        displayWalletPassword: _cubit.hasWalletPassword,
        onPrivateKeyChange: (_) {
          if (_cubit.type == WalletType.nano || _cubit.type == WalletType.banano) {
            _cubit.setButtonEnabled(_isValidSeedKey());
          }
        },
        onViewKeyEntered: (entered) {
          if (_cubit.onlyViewKeyRestore || _cubit.type == WalletType.litecoin) {
            _cubit.setButtonEnabled(entered);
          }
        },
        onPasswordChange: _cubit.setWalletPassword,
        onRepeatedPasswordChange: _cubit.setRepeatedWalletPassword,
        onHeightOrDateEntered: _cubit.setButtonEnabled,
      );

  void _validateOnChange({bool isPolyseed = false}) {
    if (isPolyseed || !_cubit.hasBlockchainHeightSelector) {
      _cubit.setButtonEnabled(_isValidSeed());
      return;
    }

    final hasHeight = _seedFormKey.currentState?.blockchainHeightKey.currentState
            ?.restoreHeightController.text.isNotEmpty ??
        false;
    if (hasHeight) {
      _cubit.setButtonEnabled(_isValidSeed());
    }
  }

  bool _isValidSeed() {
    final seedForm = _seedFormKey.currentState!;
    final seedPhrase = seedForm.seedWidgetStateKey.currentState!.text;
    if (_cubit.isPolyseed(seedPhrase)) {
      return true;
    }

    final seedWords = seedPhrase.split(" ");

    if (seedWords.length == 14 && _cubit.type == WalletType.wownero) {
      return true;
    }

    if (_cubit.type == WalletType.zano) {
      if (seedWords.length == 26) {
        return true;
      }
      return [12, 24].contains(seedWords.length) && zano!.isBip39Seed(seedPhrase.trim());
    }

    if (seedWords.length == 12 && _cubit.type == WalletType.monero) {
      return seedForm.blockchainHeightKey.currentState?.restoreHeightController.text.isNotEmpty ==
          true;
    }

    if ([WalletType.monero, WalletType.wownero, WalletType.haven].contains(_cubit.type) &&
        seedWords.length == WalletRestoreCubit.moneroSeedMnemonicLength) {
      return true;
    }

    const validBip39SeedLengths = [12, 18, 24];
    const nonBip39WalletTypes = [WalletType.wownero, WalletType.haven, WalletType.decred];
    if (!nonBip39WalletTypes.contains(_cubit.type) &&
        !validBip39SeedLengths.contains(seedWords.length)) {
      return false;
    }

    if (_cubit.type == WalletType.decred && ![12, 15, 24].contains(seedWords.length)) {
      return false;
    }

    final words = seedForm.seedWidgetStateKey.currentState!.words.toSet();
    return seedWords.toSet().difference(words).isEmpty;
  }

  bool _isValidSeedKey() {
    final seedKey = _keysFormKey.currentState!.privateKeyController.text;
    return seedKey.length == 64 || seedKey.length == 128;
  }

  Map<String, dynamic> _collectCredentials() {
    final credentials = <String, dynamic>{};

    if (_cubit.state.mode == WalletRestoreMode.seed) {
      final seedForm = _seedFormKey.currentState!;
      credentials["seed"] = seedForm.seedWidgetStateKey.currentState!.text;
      if (_cubit.hasBlockchainHeightSelector) {
        credentials["height"] = seedForm.blockchainHeightKey.currentState?.height ?? -1;
      }
      credentials["passphrase"] = _seedSettingsCubit.state.passphrase;
      credentials["name"] = seedForm.nameTextEditingController.text;
    } else {
      final keysForm = _keysFormKey.currentState!;
      credentials["name"] = keysForm.nameTextEditingController.text;
      if (_cubit.hasRestoreFromPrivateKey) {
        credentials["private_key"] = keysForm.privateKeyController.text;
        if (_cubit.hasBlockchainHeightSelector) {
          credentials["height"] = keysForm.blockchainHeightKey.currentState?.height;
        }
      } else {
        credentials["viewKey"] = keysForm.viewKeyController.text;
        if (!_cubit.onlyViewKeyRestore) {
          credentials["address"] = keysForm.addressController.text;
          credentials["spendKey"] = keysForm.spendKeyController.text;
          credentials["scanSecret"] = keysForm.scanSecretController.text;
          credentials["spendPubkey"] = keysForm.spendPubkeyController.text;
          credentials["height"] = keysForm.blockchainHeightKey.currentState?.height;
        }
      }
    }

    credentials["derivationInfo"] = _derivationInfo;
    credentials["walletType"] = _cubit.type;
    return credentials;
  }

  Future<void> _confirmForm() async {
    if (_isFormProcessing) {
      return;
    }
    _isFormProcessing = true;
    try {
      await _validateAndRestore();
    } catch (_) {
      _cubit.resetExecutionState();
      rethrow;
    } finally {
      _isFormProcessing = false;
    }
  }

  Future<void> _validateAndRestore() async {
    FocusManager.instance.primaryFocus?.unfocus();

    final isSeedMode = _cubit.state.mode == WalletRestoreMode.seed;
    final BuildContext? formContext;
    final GlobalKey<FormState> formKey;
    final String name;
    if (isSeedMode) {
      final seedForm = _seedFormKey.currentState!;
      formContext = _seedFormKey.currentContext;
      formKey = seedForm.formKey;
      name = seedForm.nameTextEditingController.text;
    } else {
      final keysForm = _keysFormKey.currentState!;
      formContext = _keysFormKey.currentContext;
      formKey = keysForm.formKey;
      name = keysForm.nameTextEditingController.text;
    }

    if (!formKey.currentState!.validate()) {
      return;
    }

    if (await _cubit.nameExists(name)) {
      if (formContext != null && formContext.mounted) {
        await _showNameExistsAlert(formContext);
      }
      return;
    }

    _cubit.startExecuting();

    final derivations = await _cubit.getDerivationInfo(_collectCredentials());
    if (!mounted) {
      return;
    }

    final derivationInfo = await _chooseDerivation(derivations);
    if (!mounted) {
      return;
    }

    _derivationInfo = derivationInfo;
    await _cubit.restore(_collectCredentials());
    _seedSettingsCubit.setPassphrase(null);
  }

  Future<DerivationInfo?> _chooseDerivation(List<DerivationInfo> derivations) async {
    final derivationsWithHistory = derivations.where((d) => d.transactionsCount > 0).toList();
    final derivationPathsWithHistory = derivationsWithHistory
        .map((d) => d.derivationPath)
        .whereType<String>()
        .where((path) => path.isNotEmpty)
        .toList();

    final shouldSkipChooseDerivationScreen = derivationPathsWithHistory.isNotEmpty &&
        derivationPathsWithHistory.every(_scanDerivationPaths.contains);

    if (derivationsWithHistory.length > 1 && !shouldSkipChooseDerivationScreen) {
      return await Navigator.of(context).pushNamed(
        Routes.restoreWalletChooseDerivation,
        arguments: derivations,
      ) as DerivationInfo?;
    }
    if (derivationsWithHistory.length == 1) {
      return derivationsWithHistory.first;
    }
    if (derivations.length == 1) {
      return derivations.first;
    }
    return _cubit.getCommonRestoreDerivation();
  }

  Future<void> _showNameExistsAlert(BuildContext alertContext) => showPopUp<void>(
        context: alertContext,
        builder: (dialogContext) => AlertWithOneAction(
          alertTitle: "",
          alertContent: S.of(dialogContext).wallet_name_exists,
          buttonText: S.of(dialogContext).ok,
          buttonAction: () => Navigator.of(dialogContext).pop(),
        ),
      );
}

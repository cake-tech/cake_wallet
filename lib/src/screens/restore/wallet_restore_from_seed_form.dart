import "package:cake_wallet/core/wallet_name_validator.dart";
import "package:cake_wallet/entities/seed_type.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/viewmodels/restore_wallet/seed_settings_cubit.dart";
import "package:cake_wallet/src/widgets/base_text_form_field.dart";
import "package:cake_wallet/src/widgets/blockchain_height_widget.dart";
import "package:cake_wallet/src/widgets/picker.dart";
import "package:cake_wallet/src/widgets/seed_language_picker.dart";
import "package:cake_wallet/src/widgets/seed_widget.dart";
import "package:cake_wallet/utils/show_pop_up.dart";
import "package:cake_wallet/view_model/restore/restore_wallet.dart";
import "package:cw_core/generate_name.dart";
import "package:cw_core/utils/print_verbose.dart";
import "package:cw_core/wallet_type.dart";
import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:polyseed/polyseed.dart";

class WalletRestoreFromSeedForm extends StatefulWidget {
  const WalletRestoreFromSeedForm({
    required this.displayLanguageSelector,
    required this.displayBlockHeightSelector,
    required this.type,
    required this.displayWalletPassword,
    required this.seedSettingsCubit,
    super.key,
    this.blockHeightFocusNode,
    this.restoredWallet,
    this.onHeightOrDateEntered,
    this.onSeedChange,
    this.onLanguageChange,
    this.onPasswordChange,
    this.onRepeatedPasswordChange,
  });

  final WalletType type;
  final bool displayLanguageSelector;
  final bool displayBlockHeightSelector;
  final bool displayWalletPassword;
  final SeedSettingsCubit seedSettingsCubit;
  final FocusNode? blockHeightFocusNode;
  final RestoredWallet? restoredWallet;
  final void Function(bool)? onHeightOrDateEntered;
  final void Function(String)? onSeedChange;
  final void Function(String)? onLanguageChange;
  final void Function(String)? onPasswordChange;
  final void Function(String)? onRepeatedPasswordChange;

  @override
  WalletRestoreFromSeedFormState createState() => WalletRestoreFromSeedFormState();
}

class WalletRestoreFromSeedFormState extends State<WalletRestoreFromSeedForm> {
  static const _defaultLanguage = "English";

  final seedWidgetStateKey = GlobalKey<SeedWidgetState>();
  final blockchainHeightKey = GlobalKey<BlockchainHeightState>();
  final formKey = GlobalKey<FormState>();
  final nameTextEditingController = TextEditingController();
  final _languageController = TextEditingController();
  final _seedTypeController = TextEditingController();

  TextEditingController? _passwordController;
  TextEditingController? _repeatedPasswordController;
  late MoneroSeedType _selectedSeedType;
  String _language = _defaultLanguage;

  bool get isPolyseed =>
      widget.seedSettingsCubit.state.moneroSeedType == MoneroSeedType.polyseed &&
      [WalletType.monero, WalletType.wownero].contains(widget.type);

  bool get isBip39 =>
      widget.seedSettingsCubit.state.moneroSeedType == MoneroSeedType.bip39 &&
      widget.type == WalletType.monero;

  bool get _isWowneroSeed => _selectedSeedType == MoneroSeedType.wowneroSeed;

  @override
  void initState() {
    super.initState();
    _setSeedType(
      widget.type == WalletType.monero
          ? widget.seedSettingsCubit.state.moneroSeedType
          : MoneroSeedType.defaultSeedType,
    );
    _setLanguageLabel(_language);

    if (widget.displayWalletPassword) {
      _passwordController = TextEditingController()..addListener(_onPasswordChanged);
      _repeatedPasswordController = TextEditingController()
        ..addListener(_onRepeatedPasswordChanged);
    }
  }

  @override
  void dispose() {
    _passwordController
      ?..removeListener(_onPasswordChanged)
      ..dispose();
    _repeatedPasswordController
      ?..removeListener(_onRepeatedPasswordChanged)
      ..dispose();
    nameTextEditingController.dispose();
    _languageController.dispose();
    _seedTypeController.dispose();
    super.dispose();
  }

  void _onPasswordChanged() => widget.onPasswordChange?.call(_passwordController!.text);

  void _onRepeatedPasswordChanged() =>
      widget.onRepeatedPasswordChange?.call(_repeatedPasswordController!.text);

  void _onMoneroSeedTypeChanged() {
    final seedType = widget.seedSettingsCubit.state.moneroSeedType;
    if (seedType == _selectedSeedType) {
      return;
    }
    _setSeedType(seedType);
    _changeLanguage(_defaultLanguage, isPolyseed || isBip39);
  }

  void _onSeedChange(String seed) {
    final wordCount = seed.split(" ").length;

    if ([WalletType.monero, WalletType.wownero].contains(widget.type) &&
        (wordCount == 12 || Polyseed.isValidSeed(seed))) {
      try {
        final lang = PolyseedLang.getByPhrase(seed);
        _changeSeedType(
          widget.type == WalletType.monero && wordCount == 12
              ? MoneroSeedType.bip39
              : MoneroSeedType.polyseed,
        );
        _changeLanguage(lang.nameEnglish, true);
      } catch (e) {
        printV(e);
      }
    }

    if (widget.type == WalletType.wownero && wordCount == 14) {
      _changeSeedType(MoneroSeedType.wowneroSeed);
    }

    widget.onSeedChange?.call(seed);
  }

  @override
  Widget build(BuildContext context) => BlocListener<SeedSettingsCubit, SeedSettingsState>(
        bloc: widget.seedSettingsCubit,
        listenWhen: (previous, current) => previous.moneroSeedType != current.moneroSeedType,
        listener: (_, __) => _onMoneroSeedTypeChanged(),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              const SizedBox(height: 8),
              Form(
                key: formKey,
                child: BaseTextFormField(
                  key: const ValueKey("wallet_restore_from_seed_wallet_name_textfield_key"),
                  controller: nameTextEditingController,
                  hintText: S.of(context).wallet_name,
                  suffixIcon: IconButton(
                    key: const ValueKey("wallet_restore_from_seed_wallet_name_refresh_button_key"),
                    onPressed: _generateWalletName,
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12.0),
                        color: Theme.of(context).colorScheme.surface,
                      ),
                      width: 34,
                      height: 34,
                      child: Image.asset(
                        "assets/images/refresh_icon.png",
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  validator: WalletNameValidator(),
                ),
              ),
              const SizedBox(height: 20),
              SeedWidget(
                key: seedWidgetStateKey,
                initialSeed: widget.restoredWallet?.mnemonicSeed,
                language: _language,
                type: widget.type,
                onSeedChange: _onSeedChange,
                seedTextFieldKey:
                    const ValueKey("wallet_restore_from_seed_wallet_seeds_textfield_key"),
                pasteButtonKey:
                    const ValueKey("wallet_restore_from_seed_wallet_seeds_paste_button_key"),
              ),
              if ([WalletType.monero, WalletType.wownero].contains(widget.type))
                GestureDetector(
                  key: const ValueKey("wallet_restore_from_seed_seedtype_picker_button_key"),
                  onTap: _showSeedTypePicker,
                  child: Container(
                    color: Colors.transparent,
                    padding: const EdgeInsets.only(top: 20.0),
                    child: IgnorePointer(
                      child: BaseTextFormField(
                        controller: _seedTypeController,
                        enableInteractiveSelection: false,
                        readOnly: true,
                        suffixIcon: _expandIcon,
                        textStyle: _pickerTextStyle,
                      ),
                    ),
                  ),
                ),
              if (widget.displayWalletPassword) ...[
                BaseTextFormField(
                  key: const ValueKey("password"),
                  controller: _passwordController,
                  hintText: S.of(context).password,
                  obscureText: true,
                ),
                BaseTextFormField(
                  key: const ValueKey("repeat_wallet_password"),
                  controller: _repeatedPasswordController,
                  hintText: S.of(context).repeat_wallet_password,
                  obscureText: true,
                ),
              ],
              if (widget.displayLanguageSelector && !_isWowneroSeed)
                GestureDetector(
                  onTap: _showLanguagePicker,
                  child: Container(
                    color: Colors.transparent,
                    padding: const EdgeInsets.only(top: 20.0),
                    child: IgnorePointer(
                      child: BaseTextFormField(
                        controller: _languageController,
                        enableInteractiveSelection: false,
                        readOnly: true,
                        suffixIcon: _expandIcon,
                        textStyle: _pickerTextStyle,
                      ),
                    ),
                  ),
                ),
              if (!isPolyseed && widget.displayBlockHeightSelector)
                BlockchainHeightWidget(
                  focusNode: widget.blockHeightFocusNode,
                  key: blockchainHeightKey,
                  blockHeightTextFieldKey:
                      const ValueKey("wallet_restore_from_seed_blockheight_textfield_key"),
                  onHeightOrDateEntered: widget.onHeightOrDateEntered,
                  hasDatePicker: [
                    WalletType.monero,
                    WalletType.wownero,
                    WalletType.zcash,
                    WalletType.zano,
                  ].contains(widget.type),
                  walletType: widget.type,
                ),
            ],
          ),
        ),
      );

  TextStyle? get _pickerTextStyle => Theme.of(context).textTheme.labelLarge?.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      );

  Widget get _expandIcon => Container(
        padding: const EdgeInsets.all(18),
        width: 24,
        height: 24,
        child: Image.asset(
          "assets/images/arrow_bottom_purple_icon.png",
          height: 8,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      );

  Future<void> _generateWalletName() async {
    final generatedName = await generateName();
    if (!mounted) {
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    nameTextEditingController
      ..text = generatedName
      ..selection = TextSelection.collapsed(offset: generatedName.length);
  }

  Future<void> _showSeedTypePicker() {
    final items = _seedTypeItems();
    final selectedIndex = items.indexOf(_selectedSeedType);
    return showPopUp<void>(
      context: context,
      builder: (_) => Picker(
        items: items,
        selectedAtIndex: selectedIndex < 0 ? 0 : selectedIndex,
        mainAxisAlignment: MainAxisAlignment.start,
        onItemSelected: _changeSeedType,
        isSeparated: false,
      ),
    );
  }

  Future<void> _showLanguagePicker() => showPopUp<void>(
        context: context,
        builder: (_) => SeedLanguagePicker(
          selected: _language,
          onItemSelected: (language) => _changeLanguage(language, isPolyseed || isBip39),
          seedType: widget.seedSettingsCubit.state.moneroSeedType,
        ),
      );

  void _changeLanguage(String language, [bool useBip39Wordlist = false]) {
    final prefixedLanguage = useBip39Wordlist
        ? "POLYSEED_$language"
        : _isWowneroSeed
            ? "WOWSEED_$language"
            : language;
    setState(() {
      _language = prefixedLanguage;
      seedWidgetStateKey.currentState?.changeSeedLanguage(prefixedLanguage);
      _setLanguageLabel(prefixedLanguage);
    });
    widget.onLanguageChange?.call(prefixedLanguage);
  }

  void _setLanguageLabel(String language) => _languageController.text =
      "${language.replaceAll("POLYSEED_", "")} (${S.current.seed_language})";

  void _changeSeedType(MoneroSeedType seedType) {
    widget.seedSettingsCubit.setMoneroSeedType(seedType);
    _setSeedType(seedType);
    _changeLanguage(_defaultLanguage, isPolyseed || isBip39);
  }

  void _setSeedType(MoneroSeedType seedType) {
    _selectedSeedType = seedType;
    _seedTypeController.text = seedType.toString();
  }

  List<MoneroSeedType> _seedTypeItems() {
    switch (widget.type) {
      case WalletType.monero:
        return [MoneroSeedType.legacy, MoneroSeedType.polyseed, MoneroSeedType.bip39];
      case WalletType.wownero:
        return [MoneroSeedType.legacy, MoneroSeedType.polyseed, MoneroSeedType.wowneroSeed];
      default:
        return [MoneroSeedType.legacy];
    }
  }
}

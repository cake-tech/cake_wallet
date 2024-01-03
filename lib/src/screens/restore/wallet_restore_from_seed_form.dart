import 'package:cake_wallet/core/wallet_name_validator.dart';
import 'package:cake_wallet/entities/generate_name.dart';
import 'package:cake_wallet/entities/seed_type.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/widgets/base_text_form_field.dart';
import 'package:cake_wallet/src/widgets/blockchain_height_widget.dart';
import 'package:cake_wallet/src/widgets/picker.dart';
import 'package:cake_wallet/src/widgets/seed_language_picker.dart';
import 'package:cake_wallet/src/widgets/seed_widget.dart';
import 'package:cake_wallet/themes/extensions/send_page_theme.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:cake_wallet/view_model/seed_type_view_model.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:flutter/material.dart';
import 'package:mobx/mobx.dart';
import 'package:polyseed/polyseed.dart';

class WalletRestoreFromSeedForm extends StatefulWidget {
  WalletRestoreFromSeedForm(
      {Key? key,
      required this.displayLanguageSelector,
      required this.displayBlockHeightSelector,
      required this.type,
      required this.seedTypeViewModel,
      this.blockHeightFocusNode,
      this.onHeightOrDateEntered,
      this.onSeedChange,
      this.onLanguageChange})
      : super(key: key);

  final WalletType type;
  final bool displayLanguageSelector;
  final bool displayBlockHeightSelector;
  final SeedTypeViewModel seedTypeViewModel;
  final FocusNode? blockHeightFocusNode;
  final Function(bool)? onHeightOrDateEntered;
  final void Function(String)? onSeedChange;
  final void Function(String)? onLanguageChange;

  @override
  WalletRestoreFromSeedFormState createState() => WalletRestoreFromSeedFormState('English');
}

class WalletRestoreFromSeedFormState extends State<WalletRestoreFromSeedForm> {
  WalletRestoreFromSeedFormState(this.language)
      : seedWidgetStateKey = GlobalKey<SeedWidgetState>(),
        blockchainHeightKey = GlobalKey<BlockchainHeightState>(),
        formKey = GlobalKey<FormState>(),
        languageController = TextEditingController(),
        nameTextEditingController = TextEditingController(),
        seedTypeController = TextEditingController();

  final GlobalKey<SeedWidgetState> seedWidgetStateKey;
  final GlobalKey<BlockchainHeightState> blockchainHeightKey;
  final TextEditingController languageController;
  final TextEditingController nameTextEditingController;
  final TextEditingController seedTypeController;
  final GlobalKey<FormState> formKey;
  late ReactionDisposer moneroSeedTypeReaction;
  String language;

  @override
  void initState() {
    _setSeedType(widget.seedTypeViewModel.moneroSeedType);
    _setLanguageLabel(language);
    moneroSeedTypeReaction =
        reaction((_) => widget.seedTypeViewModel.moneroSeedType, (SeedType item) {
      _setSeedType(item);
      _changeLanguage('English');
    });

    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    moneroSeedTypeReaction();
  }

  void onSeedChange(String seed) {
    if (widget.type == WalletType.monero && Polyseed.isValidSeed(seed)) {
      final lang = PolyseedLang.getByPhrase(seed);

      _changeSeedType(SeedType.polyseed);
      _changeLanguage(lang.nameEnglish);
    }
    widget.onSeedChange?.call(seed);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        padding: EdgeInsets.only(left: 24, right: 24),
        child: Column(children: [
          Form(
              key: formKey,
              child: Stack(
                alignment: Alignment.centerRight,
                children: [
                  BaseTextFormField(
                    controller: nameTextEditingController,
                    hintText: S.of(context).wallet_name,
                    suffixIcon: IconButton(
                      onPressed: () async {
                        final rName = await generateName();
                        FocusManager.instance.primaryFocus?.unfocus();

                        setState(() {
                          nameTextEditingController.text = rName;
                          nameTextEditingController.selection = TextSelection.fromPosition(
                              TextPosition(offset: nameTextEditingController.text.length));
                        });
                      },
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6.0),
                          color: Theme.of(context).hintColor,
                        ),
                        width: 34,
                        height: 34,
                        child: Image.asset(
                          'assets/images/refresh_icon.png',
                          color: Theme.of(context)
                              .extension<SendPageTheme>()!
                              .textFieldButtonIconColor,
                        ),
                      ),
                    ),
                    validator: WalletNameValidator(),
                  ),
                ],
              )),
          Container(height: 20),
          SeedWidget(
              key: seedWidgetStateKey,
              language: language,
              type: widget.type,
              onSeedChange: onSeedChange),
          if (widget.type == WalletType.monero)
            GestureDetector(
              onTap: () async {
                await showPopUp<void>(
                    context: context,
                    builder: (_) => Picker(
                          items: SeedType.all,
                          selectedAtIndex: isPolyseed ? 1 : 0,
                          mainAxisAlignment: MainAxisAlignment.start,
                          onItemSelected: _changeSeedType,
                          isSeparated: false,
                        ));
              },
              child: Container(
                color: Colors.transparent,
                padding: EdgeInsets.only(top: 20.0),
                child: IgnorePointer(
                  child: BaseTextFormField(
                    controller: seedTypeController,
                    enableInteractiveSelection: false,
                    readOnly: true,
                    suffixIcon: expandIcon,
                  ),
                ),
              ),
            ),
          if (widget.displayLanguageSelector)
            GestureDetector(
                onTap: () async {
                  await showPopUp<void>(
                      context: context,
                      builder: (_) => SeedLanguagePicker(
                            selected: language,
                            onItemSelected: _changeLanguage,
                            seedType: isPolyseed ? SeedType.polyseed : SeedType.legacy,
                          ));
                },
              child: Container(
                color: Colors.transparent,
                padding: EdgeInsets.only(top: 20.0),
                child: IgnorePointer(
                  child: BaseTextFormField(
                    controller: languageController,
                    enableInteractiveSelection: false,
                    readOnly: true,
                    suffixIcon: expandIcon,
                  ),
                ),
              ),
            ),
          if (!isPolyseed && widget.displayBlockHeightSelector)
            BlockchainHeightWidget(
                focusNode: widget.blockHeightFocusNode,
                key: blockchainHeightKey,
                onHeightOrDateEntered: widget.onHeightOrDateEntered,
                hasDatePicker: widget.type == WalletType.monero),
        ]));
  }

  bool get isPolyseed => widget.seedTypeViewModel.moneroSeedType == SeedType.polyseed;

  Widget get expandIcon => Container(
        padding: EdgeInsets.all(18),
        width: 24,
        height: 24,
        child: Image.asset(
          'assets/images/arrow_bottom_purple_icon.png',
          height: 8,
          color: Theme.of(context).hintColor,
        ),
      );

  void _changeLanguage(String language) {
    final setLang = isPolyseed ? "POLYSEED_$language" : language;
    setState(() {
      this.language = setLang;
      seedWidgetStateKey.currentState!.changeSeedLanguage(setLang);
      _setLanguageLabel(setLang);
      widget.onLanguageChange?.call(setLang);
    });
  }

  void _setLanguageLabel(String language) =>
      languageController.text = '${language.replaceAll("POLYSEED_", "")} (Seed language)';

  void _changeSeedType(SeedType item) {
    _setSeedType(item);
    _changeLanguage('English');
    widget.seedTypeViewModel.setMoneroSeedType(item);
  }

  void _setSeedType(SeedType item) {
    seedTypeController.text = item.toString();
  }
}

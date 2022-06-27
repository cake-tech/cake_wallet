import 'package:cake_wallet/entities/generate_name.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:cake_wallet/view_model/wallet_restore_view_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:cake_wallet/src/screens/seed_language/widgets/seed_language_picker.dart';
import 'package:cake_wallet/src/widgets/seed_widget.dart';
import 'package:cake_wallet/src/widgets/base_text_form_field.dart';
import 'package:cake_wallet/src/widgets/blockchain_height_widget.dart';
import 'package:cake_wallet/src/widgets/base_text_form_field.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/core/wallet_name_validator.dart';

class WalletRestoreFromSeedForm extends StatefulWidget {
  WalletRestoreFromSeedForm(
      {Key key,
      @required this.displayLanguageSelector,
      @required this.displayBlockHeightSelector,
      @required this.type,
      this.blockHeightFocusNode,
      this.onHeightOrDateEntered,
      this.onSeedChange,
      this.onLanguageChange})
      : super(key: key);

  final WalletType type;
  final bool displayLanguageSelector;
  final bool displayBlockHeightSelector;
  final FocusNode blockHeightFocusNode;
  final Function(bool) onHeightOrDateEntered;
  final void Function(String) onSeedChange;
  final void Function(String) onLanguageChange;

  @override
  WalletRestoreFromSeedFormState createState() =>
      WalletRestoreFromSeedFormState('English');
}

class WalletRestoreFromSeedFormState extends State<WalletRestoreFromSeedForm> {
  WalletRestoreFromSeedFormState(this.language)
      : seedWidgetStateKey = GlobalKey<SeedWidgetState>(),
        blockchainHeightKey = GlobalKey<BlockchainHeightState>(),
        formKey = GlobalKey<FormState>(),
        languageController = TextEditingController(),
        nameTextEditingController = TextEditingController();

  final GlobalKey<SeedWidgetState> seedWidgetStateKey;
  final GlobalKey<BlockchainHeightState> blockchainHeightKey;
  final TextEditingController languageController;
  final TextEditingController nameTextEditingController;
  final GlobalKey<FormState> formKey;
  String language;

  @override
  void initState() {
    _setLanguageLabel(language);
    super.initState();
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
                validator: WalletNameValidator(),
              ),
              Container(
                width: 34,
                height: 34,
                margin: const EdgeInsets.only(bottom: 15, left: 13),
                child: InkWell(
                  onTap: () async {
                    final rName = await generateName();
                    FocusManager.instance.primaryFocus?.unfocus();
                    setState(() {
                      nameTextEditingController.text = rName;
                      nameTextEditingController.selection =
                          TextSelection.fromPosition(TextPosition(
                              offset: nameTextEditingController.text.length));
                    });
                  },
                  child: Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                          color: Theme.of(context).hintColor,
                          borderRadius: BorderRadius.all(Radius.circular(6))),
                      child: Image.asset('assets/images/refresh_icon.png',
                          color: Theme.of(context)
                              .primaryTextTheme
                              .display1
                              .decorationColor)),
                ),
              ),
            ],
          )),
          Container(height: 20),
          SeedWidget(
              key: seedWidgetStateKey,
              language: language,
              type: widget.type,
              onSeedChange: widget.onSeedChange),
          if (widget.displayLanguageSelector)
            GestureDetector(
                onTap: () async {
                  final selected = await showPopUp<String>(
                      context: context,
                      builder: (BuildContext context) =>
                          SeedLanguagePicker(selected: language));

                  if (selected == null || selected.isEmpty) {
                    return;
                  }

                  _changeLanguage(selected);
                },
                child: Container(
                    color: Colors.transparent,
                    padding: EdgeInsets.only(top: 20.0),
                    child: IgnorePointer(
                        child: BaseTextFormField(
                            controller: languageController,
                            enableInteractiveSelection: false,
                            readOnly: true)))),
          if (widget.displayBlockHeightSelector)
            BlockchainHeightWidget(
                focusNode: widget.blockHeightFocusNode,
                key: blockchainHeightKey,
                onHeightOrDateEntered: widget.onHeightOrDateEntered,
                hasDatePicker: widget.type == WalletType.monero)
        ]));
  }

  void _changeLanguage(String language) {
    setState(() {
      this.language = language;
      seedWidgetStateKey.currentState.changeSeedLanguage(language);
      _setLanguageLabel(language);
      widget.onLanguageChange?.call(language);
    });
  }

  void _setLanguageLabel(String language) =>
      languageController.text = '$language (Seed language)';
}

import 'package:mobx/mobx.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/core/validator.dart';
import 'package:cake_wallet/src/widgets/seed_language_selector.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/src/widgets/scollable_with_bottom_section.dart';
import 'package:cake_wallet/src/screens/seed_language/widgets/seed_language_picker.dart';
import 'package:cake_wallet/src/widgets/alert_with_one_action.dart';
import 'package:cake_wallet/view_model/wallet_creation_state.dart';
import 'package:cake_wallet/view_model/wallet_new_vm.dart';

class NewWalletPage extends BasePage {
  NewWalletPage(this._walletNewVM);

  final WalletNewVM _walletNewVM;

  @override
  String get title => S.current.new_wallet;

  @override
  Widget body(BuildContext context) => WalletNameForm(_walletNewVM);
}

class WalletNameForm extends StatefulWidget {
  WalletNameForm(this._walletNewVM);

  final WalletNewVM _walletNewVM;

  @override
  _WalletNameFormState createState() => _WalletNameFormState(_walletNewVM);
}

class _WalletNameFormState extends State<WalletNameForm> {
  _WalletNameFormState(this._walletNewVM);

  static const aspectRatioImage = 1.22;

  final walletNameImage = Image.asset('assets/images/wallet_name.png');
  final _formKey = GlobalKey<FormState>();
  final _languageSelectorKey = GlobalKey<SeedLanguageSelectorState>();
  ReactionDisposer _stateReaction;
  final WalletNewVM _walletNewVM;

  @override
  void initState() {
    _stateReaction ??=
        reaction((_) => _walletNewVM.state, (WalletCreationState state) {
      if (state is WalletCreatedSuccessfully) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }

      if (state is WalletCreationFailure) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          showDialog<void>(
              context: context,
              builder: (_) {
                return AlertWithOneAction(
                    alertTitle: S.current.new_wallet,
                    alertContent: state.error,
                    buttonText: S.of(context).ok,
                    buttonAction: () => Navigator.of(context).pop());
              });
        });
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(top: 24),
      child: ScrollableWithBottomSection(
          contentPadding: EdgeInsets.only(left: 24, right: 24, bottom: 24),
          content:
              Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
            Padding(
              padding: EdgeInsets.only(left: 12, right: 12),
              child: AspectRatio(
                  aspectRatio: aspectRatioImage,
                  child: FittedBox(child: walletNameImage, fit: BoxFit.fill)),
            ),
            Padding(
              padding: EdgeInsets.only(top: 24),
              child: Form(
                  key: _formKey,
                  child: TextFormField(
                      onChanged: (value) => _walletNewVM.name = value,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 20.0,
                          fontWeight: FontWeight.w600,
                          color:
                              Theme.of(context).primaryTextTheme.title.color),
                      decoration: InputDecoration(
                          hintStyle: TextStyle(
                              fontSize: 16.0,
                              color: Theme.of(context)
                                  .primaryTextTheme
                                  .caption
                                  .color),
                          hintText: S.of(context).wallet_name,
                          focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(
                                  color: Theme.of(context).dividerColor,
                                  width: 1.0)),
                          enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(
                                  color: Theme.of(context).dividerColor,
                                  width: 1.0))),
                      validator: WalletNameValidator())),
            ),
            if (_walletNewVM.hasLanguageSelector) ...[
              Padding(
                padding: EdgeInsets.only(top: 40),
                child: Text(
                  S.of(context).seed_language_choose,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).primaryTextTheme.title.color),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(top: 24),
                child: SeedLanguageSelector(
                    key: _languageSelectorKey,
                    initialSelected: defaultSeedLanguage),
              )
            ]
          ]),
          bottomSectionPadding:
              EdgeInsets.only(left: 24, right: 24, bottom: 24),
          bottomSection: Observer(
            builder: (context) {
              return LoadingPrimaryButton(
                onPressed: _confirmForm,
                text: S.of(context).continue_text,
                color: Colors.green,
                textColor: Colors.white,
                isLoading: _walletNewVM.state is WalletCreatedSuccessfully,
                isDisabled: _walletNewVM.name.isEmpty,
              );
            },
          )),
    );
  }

  void _confirmForm() {
    if (!_formKey.currentState.validate()) {
      return;
    }

    _walletNewVM.create(
        options: _walletNewVM.hasLanguageSelector
            ? _languageSelectorKey.currentState.selected
            : null);
  }
}

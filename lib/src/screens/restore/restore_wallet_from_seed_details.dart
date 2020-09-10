import 'package:cake_wallet/palette.dart';
import 'package:mobx/mobx.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/core/validator.dart';
import 'package:cake_wallet/view_model/wallet_creation_state.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/widgets/blockchain_height_widget.dart';
import 'package:cake_wallet/src/widgets/scollable_with_bottom_section.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/src/widgets/alert_with_one_action.dart';
import 'package:cake_wallet/src/widgets/base_text_form_field.dart';
import 'package:cake_wallet/view_model/wallet_restoration_from_seed_vm.dart';

class RestoreWalletFromSeedDetailsPage extends BasePage {
  RestoreWalletFromSeedDetailsPage(
      {@required this.walletRestorationFromSeedVM});

  final WalletRestorationFromSeedVM walletRestorationFromSeedVM;

  @override
  String get title => S.current.restore_wallet_restore_description;

  @override
  Widget body(BuildContext context) => RestoreFromSeedDetailsForm(
      walletRestorationFromSeedVM: walletRestorationFromSeedVM);
}

class RestoreFromSeedDetailsForm extends StatefulWidget {
  RestoreFromSeedDetailsForm({@required this.walletRestorationFromSeedVM});

  final WalletRestorationFromSeedVM walletRestorationFromSeedVM;

  @override
  _RestoreFromSeedDetailsFormState createState() =>
      _RestoreFromSeedDetailsFormState();
}

class _RestoreFromSeedDetailsFormState
    extends State<RestoreFromSeedDetailsForm> {
  final _formKey = GlobalKey<FormState>();
  final _blockchainHeightKey = GlobalKey<BlockchainHeightState>();
  final _nameController = TextEditingController();
  ReactionDisposer _stateReaction;

  @override
  void initState() {
    _stateReaction = reaction((_) => widget.walletRestorationFromSeedVM.state,
        (WalletCreationState state) {
      if (state is WalletCreatedSuccessfully) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }

      if (state is WalletCreationFailure) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          showDialog<void>(
              context: context,
              builder: (BuildContext context) {
                return AlertWithOneAction(
                    alertTitle: S.current.restore_title_from_seed,
                    alertContent: state.error,
                    buttonText: S.of(context).ok,
                    buttonAction: () => Navigator.of(context).pop());
              });
        });
      }
    });

    _nameController.addListener(
        () => widget.walletRestorationFromSeedVM.name = _nameController.text);
    super.initState();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _stateReaction.reaction.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(left: 24, right: 24),
      child: ScrollableWithBottomSection(
        contentPadding: EdgeInsets.only(bottom: 24.0),
        content: Form(
          key: _formKey,
          child: Column(children: <Widget>[
            Row(
              children: <Widget>[
                Flexible(
                    child: Container(
                  padding: EdgeInsets.only(top: 20.0),
                  child: BaseTextFormField(
                    controller: _nameController,
                    hintText: S.of(context).restore_wallet_name,
                    validator: WalletNameValidator(),
                  ),
                ))
              ],
            ),
            if (widget.walletRestorationFromSeedVM.hasRestorationHeight)
              BlockchainHeightWidget(
                  key: _blockchainHeightKey,
                  onHeightChange: (height) {
                    widget.walletRestorationFromSeedVM.height = height;
                    print(height);
                  }),
          ]),
        ),
        bottomSectionPadding: EdgeInsets.only(bottom: 24),
        bottomSection: Observer(builder: (_) {
          return LoadingPrimaryButton(
            onPressed: () {
              if (_formKey.currentState.validate()) {
                widget.walletRestorationFromSeedVM.create();
              }
            },
            isLoading:
                widget.walletRestorationFromSeedVM.state is WalletCreating,
            text: S.of(context).restore_recover,
            color: Palette.blueCraiola,
            textColor: Colors.white,
            isDisabled: _nameController.text.isNotEmpty,
          );
        }),
      ),
    );
  }
}

import 'package:cake_wallet/src/domain/monero/subaddress.dart';
import 'package:mobx/mobx.dart';
import 'package:provider/provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/stores/subaddress_creation/subaddress_creation_state.dart';
import 'package:cake_wallet/src/stores/subaddress_creation/subaddress_creation_store.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/palette.dart';
import 'package:cake_wallet/src/widgets/base_text_form_field.dart';

class NewSubaddressPage extends BasePage {
  NewSubaddressPage({this.subaddress});

  final Subaddress subaddress;

  @override
  String get title => S.current.new_subaddress_title;

  @override
  Color get backgroundColor => PaletteDark.historyPanel;

  @override
  Widget body(BuildContext context) => NewSubaddressForm(subaddress);

  @override
  Widget build(BuildContext context) {
    final subaddressCreationStore =
        Provider.of<SubadrressCreationStore>(context);

    reaction((_) => subaddressCreationStore.state, (SubaddressCreationState state) {
      if (state is SubaddressCreatedSuccessfully) {
        WidgetsBinding.instance
            .addPostFrameCallback((_) => Navigator.of(context).pop());
      }
    });

    return super.build(context);
  }
}

class NewSubaddressForm extends StatefulWidget {
  NewSubaddressForm(this.subaddress);

  final Subaddress subaddress;

  @override
  NewSubaddressFormState createState() => NewSubaddressFormState(subaddress);
}

class NewSubaddressFormState extends State<NewSubaddressForm> {
  NewSubaddressFormState(this.subaddress);

  final _formKey = GlobalKey<FormState>();
  final _labelController = TextEditingController();
  final Subaddress subaddress;

  @override
  void initState() {
    if (subaddress != null) _labelController.text = subaddress.label;
    super.initState();
  }

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final subaddressCreationStore =
        Provider.of<SubadrressCreationStore>(context);

    _labelController.addListener(() {
      if (_labelController.text.isNotEmpty) {
        subaddressCreationStore.setDisabledStatus(false);
      } else {
        subaddressCreationStore.setDisabledStatus(true);
      }
    });

    return Form(
        key: _formKey,
        child: Container(
          color: PaletteDark.historyPanel,
          padding: EdgeInsets.all(24.0),
          child: Column(
            children: <Widget>[
              Expanded(
                child: Center(
                  child: BaseTextFormField(
                    controller: _labelController,
                    hintText: S.of(context).new_subaddress_label_name,
                    validator: (value) {
                      subaddressCreationStore.validateSubaddressName(value);
                      return subaddressCreationStore.errorMessage;
                    }
                  )
                )
              ),
              Observer(
                builder: (_) => LoadingPrimaryButton(
                    onPressed: () async {
                      if (_formKey.currentState.validate()) {
                        if (subaddress != null) {
                          await subaddressCreationStore.setLabel(
                            addressIndex: subaddress.id,
                            label: _labelController.text
                          );
                        } else {
                          await subaddressCreationStore.add(
                              label: _labelController.text);
                        }
                      }
                    },
                    text: subaddress != null
                    ? S.of(context).rename
                    : S.of(context).new_subaddress_create,
                    color: Colors.green,
                    textColor: Colors.white,
                    isLoading:
                    subaddressCreationStore.state is SubaddressIsCreating,
                    isDisabled: subaddressCreationStore.isDisabledStatus,
                ),
              )
            ],
          ),
        )
    );
  }
}

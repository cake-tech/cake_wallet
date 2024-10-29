import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/widgets/base_text_form_field.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/view_model/settings/mweb_settings_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

class MwebNodePage extends BasePage {
  MwebNodePage(this.mwebSettingsViewModelBase)
      : _nodeUriController = TextEditingController(text: mwebSettingsViewModelBase.mwebNodeUri),
        super();

  final MwebSettingsViewModelBase mwebSettingsViewModelBase;
  final TextEditingController _nodeUriController;

  @override
  String get title => S.current.litecoin_mweb_node;

  @override
  Widget body(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: <Widget>[
              Expanded(
                child: BaseTextFormField(controller: _nodeUriController),
              )
            ],
          ),
        ),
        Positioned(
          child: Observer(
            builder: (_) => LoadingPrimaryButton(
              onPressed: () => save(context),
              text: S.of(context).save,
              color: Theme.of(context).primaryColor,
              textColor: Colors.white,
            ),
          ),
          bottom: 24,
          left: 24,
          right: 24,
        )
      ],
    );
  }

  void save(BuildContext context) {
    mwebSettingsViewModelBase.setMwebNodeUri(_nodeUriController.text);
    Navigator.pop(context);
  }
}

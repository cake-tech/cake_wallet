import 'package:cake_wallet/core/email_validator.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/widgets/base_text_form_field.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/src/widgets/scollable_with_bottom_section.dart';
import 'package:cake_wallet/typography.dart';
import 'package:cake_wallet/view_model/ionia/ionia_transfer_view_model.dart';

import 'package:flutter/material.dart';

class IoniaTransferPage extends BasePage {
  IoniaTransferPage(this._viewModel)
      : _formKey = GlobalKey<FormState>(),
        _emailController = TextEditingController() {
    _emailController.text = _viewModel.email;
    _emailController.addListener(() => _viewModel.email = _emailController.text);
  }

  final GlobalKey<FormState> _formKey;

  final IoniaTransferViewModel _viewModel;

  @override
  Color get titleColor => Colors.black;

  final TextEditingController _emailController;

  @override
  Widget middle(BuildContext context) {
    return Text(
      S.current.transfer,
      style: textMediumSemiBold(
        color: Theme.of(context).accentTextTheme.display4.backgroundColor,
      ),
    );
  }

  @override
  Widget body(BuildContext context) {
  
    return ScrollableWithBottomSection(
      contentPadding: EdgeInsets.all(24),
      content: Form(
        key: _formKey,
        child: BaseTextFormField(
          hintText: S.of(context).email_address,
          keyboardType: TextInputType.emailAddress,
          validator: EmailValidator(),
          controller: _emailController,
        ),
      ),
      bottomSectionPadding: EdgeInsets.symmetric(vertical: 36, horizontal: 24),
      bottomSection: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            child: RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                text: S.current.transfer_card_redemption,
                style: TextStyle(
                  color: Theme.of(context).primaryTextTheme.title.color,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                children: [
                  TextSpan(text: ' ${S.of(context).you_wont_be_able_to_use_card} ',
                   style: TextStyle(
                      fontWeight: FontWeight.w700,
                    color: Theme.of(context).primaryTextTheme.title.color,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 22),
          PrimaryButton(
            text: S.of(context).share,
            onPressed: (){ },
            color: Theme.of(context).accentTextTheme.body2.color,
            textColor: Colors.white,
          ),
          SizedBox(height: 20),
        ],
      ),
    );
  }
}
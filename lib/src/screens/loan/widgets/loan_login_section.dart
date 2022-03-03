import 'package:cake_wallet/src/widgets/base_text_form_field.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:flutter/material.dart';

class LoanLoginSection extends StatelessWidget {
  const LoanLoginSection({
    @required this.emailFocus,
    @required this.codeFocus,
    @required this.emailController,
    @required this.codeController,
  });

  final FocusNode emailFocus;
  final TextEditingController emailController;

  final FocusNode codeFocus;
  final TextEditingController codeController;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 40,
          child: Row(
            children: [
              Expanded(
                child: BaseTextFormField(
                  textColor: Colors.white,
                  hintText: 'Email OR Phone Number',
                  focusNode: emailFocus,
                  controller: emailController,
                  placeholderTextStyle: TextStyle(color: Colors.white54),
                ),
              ),
              SizedBox(
                width: 90,
                child: PrimaryButton(
                  onPressed: () {},
                  text: 'Get code',
                  color: Colors.white.withOpacity(0.2),
                  radius: 6,
                  textColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 37),
        SizedBox(
          height: 40,
          child: Row(
            children: [
              Expanded(
                child: BaseTextFormField(
                  textColor: Colors.white,
                  hintText: 'SMS / Email Code',
                  focusNode: codeFocus,
                  controller: codeController,
                  placeholderTextStyle: TextStyle(color: Colors.white54),
                ),
              ),
              SizedBox(width: 10),
              SizedBox(
                width: 70,
                child: PrimaryButton(
                    onPressed: () {},
                    text: 'Verify',
                    color: Colors.white.withOpacity(0.2),
                    radius: 6,
                    textColor: Colors.white),
              ),
              SizedBox(width: 10)
            ],
          ),
        ),
        SizedBox(height: 100),
      ],
    );
  }
}

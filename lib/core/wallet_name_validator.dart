import 'package:cake_wallet/view_model/wallet_list/wallet_list_view_model.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/core/validator.dart';
import 'package:cake_wallet/src/widgets/alert_with_one_action.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:cake_wallet/di.dart';

class WalletNameValidator extends TextValidator {
  WalletNameValidator(this.context)
      : super(
            errorMessage: S.current.error_text_wallet_name,
            pattern: '^[a-zA-Z0-9_ ]+\$',
            minLength: 1,
            maxLength: 15) {
    this.walletListViewModel = getIt.get<WalletListViewModel>();
  }

  final BuildContext context;
  WalletListViewModel walletListViewModel;

  @override
  String call(String value) {
    final isTextValid = super.isValid(value);

    if (isTextValid) {
      bool nameExists = false;
      for (final element in walletListViewModel.wallets) {
        nameExists = false;
        if (value.toLowerCase() == element.name.toLowerCase()) {
          nameExists = true;
          break;
        }
      }

      if (nameExists) {
        showPopUp<void>(
            context: context,
            builder: (_) {
              return AlertWithOneAction(
                  alertTitle: '',
                  alertContent: S.of(context).wallet_name_exists,
                  buttonText: S.of(context).ok,
                  buttonAction: () => Navigator.of(context).pop());
            });
        return '';
      }
      return null;
    } else {
      return this.errorMessage;
    }
  }
}

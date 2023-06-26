import 'package:another_flushbar/flushbar.dart';
import 'package:cake_wallet/core/auth_service.dart';
import 'package:cake_wallet/core/wallet_name_validator.dart';
import 'package:cake_wallet/palette.dart';
import 'package:cake_wallet/src/widgets/alert_with_one_action.dart';
import 'package:cake_wallet/src/widgets/alert_with_two_actions.dart';
import 'package:cake_wallet/utils/show_bar.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:cake_wallet/view_model/wallet_list/wallet_list_item.dart';
import 'package:cake_wallet/view_model/wallet_list/wallet_list_view_model.dart';
import 'package:cake_wallet/view_model/wallet_new_vm.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/src/widgets/base_text_form_field.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:mobx/mobx.dart';

class WalletEditPage extends BasePage {
  WalletEditPage(
      {required this.walletListViewModel,
      required this.editingWallet,
      required this.walletNewVM,
      required this.authService})
      : _formKey = GlobalKey<FormState>(),
        _labelController = TextEditingController(),
        super() {
    reaction((_) => walletListViewModel.newName, (String newName) {
      walletListViewModel.newName = newName;
    });
    _labelController
        .addListener(() => walletListViewModel.newName = _labelController.text);
    _labelController.text = editingWallet.name;
  }

  final GlobalKey<FormState> _formKey;
  final TextEditingController _labelController;

  final WalletListViewModel walletListViewModel;
  final WalletNewVM walletNewVM;
  final WalletListItem editingWallet;
  final AuthService authService;

  @override
  String get title => S.current.wallet_list_edit_wallet;

  @override
  Widget body(BuildContext context) => WalletEditBody(
      walletListViewModel: walletListViewModel,
      editingWallet: editingWallet,
      authService: authService,
      walletNewVM: walletNewVM,
      formKey: _formKey,
      labelController: _labelController);
}

class WalletEditBody extends StatefulWidget {
  WalletEditBody(
      {required this.walletListViewModel,
      required this.editingWallet,
      required this.authService,
      required this.formKey,
      required this.walletNewVM,
      required this.labelController});

  final GlobalKey<FormState> formKey;
  final TextEditingController labelController;

  final WalletListViewModel walletListViewModel;
  final AuthService authService;
  final WalletListItem editingWallet;
  final WalletNewVM walletNewVM;

  @override
  WalletEditBodyState createState() => WalletEditBodyState();
}

class WalletEditBodyState extends State<WalletEditBody> {
  Flushbar<void>? _progressBar;

  @override
  Widget build(BuildContext context) {
    return Form(
        key: widget.formKey,
        child: Container(
          padding: EdgeInsets.all(24.0),
          child: Column(
            children: <Widget>[
              Expanded(
                  child: Center(
                      child: BaseTextFormField(
                          controller: widget.labelController,
                          hintText: S.of(context).wallet_list_wallet_name,
                          validator: WalletNameValidator()))),
              Row(
                children: <Widget>[
                  Flexible(
                      child: Container(
                    padding: EdgeInsets.only(right: 8.0),
                    child: LoadingPrimaryButton(
                        onPressed: _removeWallet,
                        text: S.of(context).delete,
                        color: Palette.red,
                        textColor: Colors.white),
                  )),
                  Flexible(
                      child: Container(
                    padding: EdgeInsets.only(left: 8.0),
                    child: Observer(builder: (context) {
                      return LoadingPrimaryButton(
                        onPressed: () async {
                          if (widget.formKey.currentState?.validate() ??
                              false) {
                            if (widget.walletNewVM.nameExists(
                                widget.walletListViewModel.newName)) {
                              showPopUp<void>(
                                  context: context,
                                  builder: (_) {
                                    return AlertWithOneAction(
                                        alertTitle: '',
                                        alertContent:
                                            S.of(context).wallet_name_exists,
                                        buttonText: S.of(context).ok,
                                        buttonAction: () =>
                                            Navigator.of(context).pop());
                                  });
                            } else {
                              try {
                                await widget.walletListViewModel
                                    .changeName(widget.editingWallet);
                                Navigator.of(context).pop();
                              } catch (e) {}
                            }
                          }
                        },
                        text: S.of(context).save,
                        color:
                            Theme.of(context).accentTextTheme.bodyLarge!.color!,
                        textColor: Colors.white,
                        isDisabled: widget.walletListViewModel.newName.isEmpty,
                      );
                    }),
                  )),
                ],
              )
            ],
          ),
        ));
  }

  void _removeWallet() async {
    widget.authService.authenticateAction(context,
        onAuthSuccess: (isAuthenticatedSuccessfully) async {
      if (!isAuthenticatedSuccessfully) {
        return;
      }

      _onSuccessfulAuth();
    });
  }

  void _onSuccessfulAuth() async {
    bool confirmed = false;

    await showPopUp<void>(
        context: context,
        builder: (BuildContext dialogContext) {
          return AlertWithTwoActions(
              alertTitle: S.of(context).delete_wallet,
              alertContent: S
                  .of(context)
                  .delete_wallet_confirm_message(widget.editingWallet.name),
              leftButtonText: S.of(context).cancel,
              rightButtonText: S.of(context).delete,
              actionLeftButton: () => Navigator.of(dialogContext).pop(),
              actionRightButton: () {
                confirmed = true;
                Navigator.of(dialogContext).pop();
              });
        });

    if (confirmed) {
      Navigator.of(context).pop();

      try {
        changeProcessText(S
            .of(context)
            .wallet_list_removing_wallet(widget.editingWallet.name));
        await widget.walletListViewModel.remove(widget.editingWallet);
        hideProgressText();
      } catch (e) {
        changeProcessText(
          S.of(context).wallet_list_failed_to_remove(
              widget.editingWallet.name, e.toString()),
        );
      }
    }
  }

  void changeProcessText(String text) {
    _progressBar = createBar<void>(text, duration: null)..show(context);
  }

  Future<void> hideProgressText() async {
    await Future.delayed(Duration(milliseconds: 50), () {
      _progressBar?.dismiss();
      _progressBar = null;
    });
  }
}

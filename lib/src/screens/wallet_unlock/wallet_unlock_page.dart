import 'package:another_flushbar/flushbar.dart';
import 'package:cake_wallet/core/authentication_request_data.dart';
import 'package:cake_wallet/core/execution_state.dart';
import 'package:cake_wallet/core/totp_request_details.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/screens/wallet_unlock/wallet_unlock_arguments.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/themes/extensions/cake_text_theme.dart';
import 'package:cake_wallet/themes/extensions/new_wallet_theme.dart';
import 'package:cake_wallet/utils/exception_handler.dart';
import 'package:cake_wallet/utils/responsive_layout_util.dart';
import 'package:cake_wallet/utils/show_bar.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/view_model/wallet_password_auth_view_model.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

class WalletUnlockPage extends BasePage {
  WalletUnlockPage(
      {required this.walletPasswordAuthViewModel,
      required this.onAuthenticationFinished,
      required this.authPasswordHandler,
      bool closable = false,
      bool isVerifiable = false})
      : this.isClosable = closable,
        this.isVerifiable = isVerifiable,
        _passwordController = TextEditingController() {
    _passwordController.text = walletPasswordAuthViewModel.password;
    _passwordController
        .addListener(() => walletPasswordAuthViewModel.password = _passwordController.text);
  }

  final WalletPasswordAuthViewModel walletPasswordAuthViewModel;
  final OnAuthenticationFinished onAuthenticationFinished;
  final AuthPasswordHandler authPasswordHandler;
  final bool isClosable;
  final bool isVerifiable;
  final TextEditingController _passwordController;

  @override
  Widget? leading(BuildContext context) {
    return isClosable ? super.leading(context) : null;
  }

  @override
  Widget body(BuildContext context) {
    Future<void> close({String? route, arguments}) async {
      if (route != null) {
        Navigator.of(context).pushReplacementNamed(route, arguments: arguments);
      } else {
        Navigator.of(context).pop();
      }
    }

    void onFailure(String error) {
      walletPasswordAuthViewModel.state = FailureState(error);
      showBar<void>(context, S.of(context).failed_authentication(error),
          duration: Duration(seconds: 3));
      onAuthenticationFinished(
          AuthResponse(error: S.of(context).failed_authentication(error), close: close));
    }

    return Center(
        child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: ResponsiveLayoutUtil.kDesktopMaxWidthConstraint),
            child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                        Text(walletPasswordAuthViewModel.walletName,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w500,
                                color: Theme.of(context).extension<CakeTextTheme>()!.titleColor)),
                        SizedBox(height: 24),
                        Form(
                            child: TextFormField(
                                onChanged: (value) => null,
                                controller: _passwordController,
                                textAlign: TextAlign.center,
                                obscureText: true,
                                style: TextStyle(
                                    fontSize: 20.0,
                                    fontWeight: FontWeight.w600,
                                    color:
                                        Theme.of(context).extension<CakeTextTheme>()!.titleColor),
                                decoration: InputDecoration(
                                    hintStyle: TextStyle(
                                        fontSize: 18.0,
                                        fontWeight: FontWeight.w500,
                                        color: Theme.of(context)
                                            .extension<NewWalletTheme>()!
                                            .hintTextColor),
                                    hintText: S.of(context).enter_wallet_password,
                                    focusedBorder: UnderlineInputBorder(
                                        borderSide: BorderSide(
                                            color: Theme.of(context)
                                                .extension<NewWalletTheme>()!
                                                .underlineColor,
                                            width: 1.0)),
                                    enabledBorder: UnderlineInputBorder(
                                        borderSide: BorderSide(
                                            color: Theme.of(context)
                                                .extension<NewWalletTheme>()!
                                                .underlineColor,
                                            width: 1.0)))))
                      ])),
                  Observer(builder: (_) {
                    return Padding(
                        padding: EdgeInsets.only(bottom: 24),
                        child: LoadingPrimaryButton(
                            onPressed: () async {
                              Flushbar<void>? loadingBar;
                              if (!isVerifiable)
                                loadingBar = createBar<void>(S.of(context).loading_your_wallet)
                                  ..show(context);

                              walletPasswordAuthViewModel.state = IsExecutingState();
                              dynamic payload;

                              try {
                                payload = await authPasswordHandler(
                                    walletPasswordAuthViewModel.walletName,
                                    walletPasswordAuthViewModel.walletType,
                                    walletPasswordAuthViewModel.password);
                              } catch (err, stack) {
                                loadingBar?.dismiss();
                                onFailure(S.of(context).invalid_password);
                                ExceptionHandler.onError(
                                    FlutterErrorDetails(exception: err, stack: stack));
                                return;
                              }

                              loadingBar?.dismiss();

                              if (!walletPasswordAuthViewModel.useTotp) {
                                onAuthenticationFinished(
                                    AuthResponse(success: true, close: close, payload: payload));
                              } else {
                                Navigator.of(context).pushReplacementNamed(
                                  Routes.totpAuthCodePage,
                                  arguments: TotpAuthArgumentsModel(
                                    isForSetup: false,
                                    isClosable: isClosable,
                                    onTotpAuthenticationFinished: (totpAuth) async {
                                      if (!totpAuth.success) {
                                        onFailure(totpAuth.error!);
                                        return;
                                      }

                                      onAuthenticationFinished(AuthResponse(
                                          success: true, close: totpAuth.close, payload: payload));
                                    },
                                  ),
                                );
                              }
                            },
                            text: S.of(context).unlock,
                            color: Colors.green,
                            textColor: Colors.white,
                            isLoading: walletPasswordAuthViewModel.state is IsExecutingState,
                            isDisabled: walletPasswordAuthViewModel.state is IsExecutingState ||
                                walletPasswordAuthViewModel.password.length == 0));
                  })
                ])));
  }
}

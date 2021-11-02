import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:mobx/mobx.dart';
import 'package:cake_wallet/src/screens/yat/widgets/yat_close_button.dart';
import 'package:cake_wallet/view_model/send/send_view_model_state.dart';
import 'package:cake_wallet/src/screens/yat/circle_clipper.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/widgets/alert_with_one_action.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/store/yat/yat_store.dart';
import 'package:cake_wallet/core/execution_state.dart';
import 'package:cake_wallet/view_model/send/send_view_model.dart';

class YatSending extends BasePage {
  YatSending(this.sendViewModel);

  static Route createRoute(SendViewModel sendViewModel) {
    return PageRouteBuilder<void>(
      transitionDuration: Duration(seconds: 1),
      reverseTransitionDuration: Duration(seconds: 1),
      opaque: false,
      barrierDismissible: false,
      pageBuilder: (context, animation, secondaryAnimation) => YatSending(sendViewModel),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final screenSize = MediaQuery.of(context).size;
        final center = Offset(screenSize.width / 2, screenSize.height / 2);
        final endRadius = screenSize.height * 1.2;
        final tween = Tween(begin: 0.0, end: endRadius);

        return ClipPath(
          clipper: CircleClipper(center, animation.drive(tween).value),
          child: child,
        );
      },
    );
  }

  final SendViewModel sendViewModel;

  @override
  Color get titleColor => Colors.white;

  @override
  bool get resizeToAvoidBottomInset => false;

  @override
  bool get extendBodyBehindAppBar => true;

  @override
  AppBarStyle get appBarStyle => AppBarStyle.transparent;

  @override
  Widget trailing(context) =>
    YatCloseButton(onClose: () => Navigator.of(context).pop());

  @override
    Widget leading(BuildContext context) => Container();

  @override
  Widget body(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Container(
            color: Colors.black,
            child: Stack(
              children: [
                Center(
                  child:FutureBuilder<String>(
                      future: visualisationForEmojiId(sendViewModel.outputs.first.address),
                      builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
                         switch (snapshot.connectionState) {
                          case ConnectionState.done:
                            if (snapshot.hasError || snapshot.data.isEmpty) {
                              return Image.asset('assets/images/yat_logo.png', width: screenWidth, color: Colors.white);
                            }

                            return Image.network(
                                snapshot.data,
                                scale: 0.7,
                                loadingBuilder: (Object z, Widget child, ImageChunkEvent loading)
                                  => loading != null
                                    ?  CupertinoActivityIndicator(animating: true)
                                    : child);
                         default:
                          return Image.asset('assets/images/yat_logo.png', width: screenWidth, color: Colors.white);
                        }
                      }),
                    ),
                Positioned(
                  bottom: 20,
                  child: Container(
                    width: screenWidth,
                    padding: EdgeInsets.fromLTRB(20, 0, 20, 10),
                    child: Column(children: [
                    Text(
                      'You are sending ${sendViewModel.outputs.first.cryptoAmount} ${sendViewModel.currency.title} to ${sendViewModel.outputs.first.address}'.toUpperCase(),
                      style: TextStyle(
                        fontSize: 28,
                        decoration: TextDecoration.none,
                        color: Theme.of(context).accentTextTheme.display3.backgroundColor),
                      textAlign: TextAlign.center),
                    Container(height: 30),
                    LoadingPrimaryButton(
                      onPressed: () {
                        sendViewModel.commitTransaction();
                        showPopUp<void>(
                            context: context,
                            builder: (BuildContext popContext) {
                              return Observer(builder: (_) {
                                final state = sendViewModel.state;

                                if (state is FailureState) {
                                  Navigator.of(context).pop();
                                }

                                if (state is TransactionCommitted) {
                                  return AlertWithOneAction(
                                      alertTitle: '',
                                      alertContent: S.of(popContext).send_success(
                                          sendViewModel.currency
                                              .toString()),
                                      buttonText: S.of(popContext).ok,
                                      buttonAction: () {
                                          Navigator.of(popContext).pop();
                                          Navigator.of(context).pop();
                                      });
                                }

                                return Offstage();
                              });
                            });
                        },
                      text: S.of(context).confirm_sending,
                      color: Theme.of(context).accentTextTheme.body2.color,
                      textColor: Colors.white,
                      isLoading: sendViewModel.state is IsExecutingState ||
                          sendViewModel.state is TransactionCommitting)])))]));
  }
}
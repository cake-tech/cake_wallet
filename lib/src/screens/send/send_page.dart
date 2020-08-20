import 'package:cake_wallet/view_model/send_view_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/screens/send/widgets/base_send_widget.dart';

class SendPage extends BasePage {
  SendPage({@required this.sendViewModel});

  final SendViewModel sendViewModel;

  @override
  String get title => sendViewModel.pageTitle;

  @override
  Color get titleColor => Colors.white;

  @override
  Color get backgroundLightColor => Colors.transparent;

  @override
  Color get backgroundDarkColor => Colors.transparent;

  @override
  bool get resizeToAvoidBottomPadding => false;

  @override
  Widget body(BuildContext context) =>
      BaseSendWidget(
        sendViewModel: sendViewModel,
        leading: leading(context),
        middle: middle(context),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomPadding: resizeToAvoidBottomPadding,
      body: Container(
        color: Theme.of(context).backgroundColor,
        child: body(context)
      )
    );
  }
}

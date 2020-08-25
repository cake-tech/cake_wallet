import 'package:cake_wallet/view_model/send_view_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/palette.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/screens/send/widgets/base_send_widget.dart';

class SendPage extends BasePage {
  SendPage({@required this.sendViewModel});

  final SendViewModel sendViewModel;

  @override
  String get title => sendViewModel.pageTitle;

  @override
  Color get backgroundLightColor => PaletteDark.nightBlue;

  @override
  Color get backgroundDarkColor => PaletteDark.nightBlue;

  @override
  bool get resizeToAvoidBottomPadding => false;

  @override
  Widget body(BuildContext context) =>
      BaseSendWidget(sendViewModel: sendViewModel);
}

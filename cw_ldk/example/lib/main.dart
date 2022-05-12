import 'package:cw_ldk_example/pages/channel/close.dart';
import 'package:cw_ldk_example/pages/channel/create.dart';
import 'package:cw_ldk_example/pages/invoice/create.dart';
import 'package:cw_ldk_example/pages/home.dart';
import 'package:cw_ldk_example/pages/info.dart';
import 'package:cw_ldk_example/pages/invoice/pay.dart';
import 'package:cw_ldk_example/pages/invoice/qr_code.dart';
import 'package:flutter/material.dart';

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      initialRoute: "/",
      routes: {
        "/": (_) => HomePage(),
        "/channel/create": (_) => CreateChannelPage(),
        "/channel/close": (_) => CloseChannelPage(),
        "/invoice/create": (_) => CreateInvoicePage(),
        "/invoice/pay": (_) => PayInvoicePage(),
        "/invoice/show_qr_code": (_) => ShowQRCodePage(),
        "/info": (_) => NodeAndChannelInfoPage(),
      },
    );
  }
}

void main() => runApp(MyApp());

import 'package:cw_ldk_example/pages/create_channel.dart';
import 'package:cw_ldk_example/pages/create_invoice.dart';
import 'package:cw_ldk_example/pages/home.dart';
import 'package:cw_ldk_example/pages/node_and_channels_info.dart';
import 'package:cw_ldk_example/pages/pay_invoice.dart';
import 'package:cw_ldk_example/pages/show_qr_code.dart';
import 'package:flutter/material.dart';

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      initialRoute: "/",
      routes: {
        "/": (_) => HomePage(),
        "/create_channel": (_) => CreateChannelPage(),
        "/create_invoice": (_) => CreateInvoicePage(),
        "/pay_invoice": (_) => PayInvoicePage(),
        "/pay_invoice/show_qr_code": (_) => ShowQRCodePage(),
        "/node_and_channel_info": (_) => NodeAndChannelInfoPage(),
      },
    );
  }
}

void main() => runApp(MyApp());

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cake_wallet/src/screens/receive/widgets/address_widget.dart';

class ReceiveWithoutSubaddress extends StatefulWidget {
  @override
  ReceiveWithoutSubaddressState createState() => ReceiveWithoutSubaddressState();
}

class ReceiveWithoutSubaddressState extends State<ReceiveWithoutSubaddress> {

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: EdgeInsets.all(35),
        child: Center(
          child: AddressWidget(isSubaddress: false),
        )
      )
    );
  }
}
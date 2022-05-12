import 'package:flutter/material.dart';

class PayInvoicePage extends StatefulWidget {
  @override
  State<PayInvoicePage> createState() => _PayInvoiceState();
}

class _PayInvoiceState extends State<PayInvoicePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text("Pay Invoice")),
        body: Center(child: Text("Pay Invoice")));
  }
}

import 'package:flutter/material.dart';

class CreateInvoicePage extends StatefulWidget {
  @override
  State<CreateInvoicePage> createState() => _CreateInvoiceState();
}

class _CreateInvoiceState extends State<CreateInvoicePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text("Create Invoice")),
        body: Center(child: Text("Create Invoice")));
  }
}

import 'package:flutter/material.dart';

class CreateInvoicePage extends StatefulWidget {
  @override
  State<CreateInvoicePage> createState() => _CreateInvoiceState();
}

class _CreateInvoiceState extends State<CreateInvoicePage> {
  TextEditingController amount;
  String bolt11;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Create Invoice")),
      body: Center(
          child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: <Widget>[
            Text("Please specify amount in satoshis"),
            TextField(
              decoration: InputDecoration(labelText: "amount"),
              controller: amount,
            ),
            ElevatedButton(
              child: Text("Create Bolt 11"),
              onPressed: () {
                setState(() {
                  bolt11 =
                      "lnbc20m1pvjluezpp5qqqsyqcyq5rqwzqfqqqsyqcyq5rqwzqfqqqsyqcyq5rqwzqfqypqhp58yjmdan79s6qqdhdzgynm4zwqd5d7xmw5fk98klysy043l2ahrqsfpp3qjmp7lwpagxun9pygexvgpjdc4jdj85fr9yq20q82gphp2nflc7jtzrcazrra7wwgzxqc8u7754cdlpfrmccae92qgzqvzq2ps8pqqqqqqpqqqqq9qqqvpeuqafqxu92d8lr6fvg0r5gv0heeeqgcrqlnm6jhphu9y00rrhy4grqszsvpcgpy9qqqqqqgqqqqq7qqzqj9n4evl6mr5aj9f58zp6fyjzup6ywn3x6sk8akg5v4tgn2q8g4fhx05wf6juaxu9760yp46454gpg5mtzgerlzezqcqvjnhjh8z3g2qqdhhwkj";
                });
              },
            ),
            if (bolt11 != null) ...[
              Container(
                margin: EdgeInsets.only(top: 10),
                child: SelectableText(bolt11),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context)
                      .pushNamed("/invoice/show_qr_code", arguments: bolt11);
                },
                child: Text("Show QR Code"),
              ),
            ]
          ],
        ),
      )),
    );
  }

  @override
  void initState() {
    super.initState();
    amount = TextEditingController();
  }

  @override
  void dispose() {
    super.dispose();
    amount.dispose();
  }
}

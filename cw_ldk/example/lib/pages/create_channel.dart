import 'package:flutter/material.dart';

class CreateChannelPage extends StatefulWidget {
  @override
  State<CreateChannelPage> createState() => _CreateChannelState();
}

class _CreateChannelState extends State<CreateChannelPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Create Channel")),
      body: Center(
          child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: <Widget>[
            Text("Please specify amount in satoshis"),
            TextField(
              decoration: InputDecoration(labelText: "amount"),
            ),
            ElevatedButton(
                onPressed: () {
                  // Navigator.pop(context);
                  showDialog<void>(
                    context: context,
                    builder: (_) => AlertDialog(
                        title: Text("Channel Created"),
                        content: Text(
                            "You successfuly created a channel with cake."),
                        actions: <Widget>[
                          TextButton(
                            child: const Text('Ok'),
                            onPressed: () {
                              final nav = Navigator.of(context);
                              nav.pop();
                              nav.pop();
                            },
                          )
                        ]),
                  );
                },
                child: Text("Create Channel"))
          ],
        ),
      )),
    );
  }
}

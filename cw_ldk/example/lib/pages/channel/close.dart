import 'package:flutter/material.dart';

class CloseChannelPage extends StatefulWidget {
  @override
  State<CloseChannelPage> createState() => _CloseChannelState();
}

class _CloseChannelState extends State<CloseChannelPage> {
  TextEditingController amount;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Close Channel")),
      body: Center(
          child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: <Widget>[
            Text("Chose which channel you want to close"),
            ElevatedButton(
              child: Text("Close Channel"),
              onPressed: () {
                // Navigator.pop(context);
                print(amount.text);
                showDialog<void>(
                  context: context,
                  builder: (_) => AlertDialog(
                      title: Text("Channel Created"),
                      content: Text("You successfuly close the channel"),
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
            )
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

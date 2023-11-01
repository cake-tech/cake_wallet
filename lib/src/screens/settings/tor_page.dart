import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:flutter/material.dart';
import 'package:socks5_proxy/socks.dart';
import 'package:tor/socks_socket.dart';
import 'package:tor/tor.dart';

class TorPage extends BasePage {
  @override
  Widget body(BuildContext context) {
    return TorPageBody();
  }
}

class TorPageBody extends StatefulWidget {
  const TorPageBody({Key? key}) : super(key: key);

  @override
  State<TorPageBody> createState() => _TorPageBodyState();
}

class _TorPageBodyState extends State<TorPageBody> {
  bool torEnabled = false;
  bool connecting = false;

  // Set the default text for the host input field.
  final hostController = TextEditingController(text: 'https://icanhazip.com/');

  // https://check.torproject.org is another good option.

  Future<void> startTor() async {
    setState(() {
      connecting = true; // Update flag
    });

    await Tor.init();

    // Start the proxy
    await Tor.instance.start();

    // Toggle started flag.
    setState(() {
      torEnabled = Tor.instance.enabled; // Update flag
      connecting = false;
    });

    print('Done awaiting; tor should be running');
  }

  Future<void> endTor() async {
    final client = HttpClient();

    // Assign connection factory.
    SocksTCPClient.assignToHttpClient(client, [
      ProxySettings(InternetAddress.loopbackIPv4, Tor.instance.port,
          password: null), // TODO Need to get from tor config file.
    ]);

    print("@@@@@@@@@@@@");
    print(Tor.instance.port);
    print(Uri.http('n4z7bdcmwk2oyddxvzaap3x2peqcplh3pzdy7tpkk5ejz5n4mhfvoxqd.onion', '/v2/rates'));

    // GET request.
    final request = await client.getUrl(
        Uri.http('n4z7bdcmwk2oyddxvzaap3x2peqcplh3pzdy7tpkk5ejz5n4mhfvoxqd.onion', '/v2/rates'));
    final response = await request.close();

    // Print response.
    var responseString = await utf8.decodeStream(response);
    print(responseString);
    // If host input left to default icanhazip.com, a Tor
    // exit node IP should be printed to the console.
    //
    // https://check.torproject.org is also good for
    // doublechecking torability.

    // Close client
    client.close();

    print('Done awaiting; tor should be stopped');
  }

  @override
  void initState() {
    super.initState();

    torEnabled = Tor.instance.enabled;
  }

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    hostController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(10),
        child: connecting
            ? ConnectingScreen()
            : torEnabled
                ? DisconnectScreen(disconnect: endTor)
                : ConnectScreen(connect: startTor),
      ),
    );
  }
}

class ConnectScreen extends StatelessWidget {
  final Function() connect;

  const ConnectScreen({super.key, required this.connect});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.blue,
            ),
            child: Icon(
              Icons.lock,
              color: Colors.white,
              size: 100,
            ),
          ),
          SizedBox(height: 20),
          Text(
            'Connect to Tor',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Your connection to the Tor network ensures privacy and security.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 30),
          ElevatedButton(
            onPressed: connect,
            style: ElevatedButton.styleFrom(
              primary: Colors.blue,
              padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: Text(
              'Connect',
              style: TextStyle(
                fontSize: 18,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DisconnectScreen extends StatelessWidget {
  final Function() disconnect;

  const DisconnectScreen({super.key, required this.disconnect});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.green,
            ),
            child: Icon(
              Icons.check,
              color: Colors.white,
              size: 100,
            ),
          ),
          SizedBox(height: 20),
          Text(
            'Connected to Tor',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 10),
          Text(
            'You are currently connected to the Tor network.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 30),
          ElevatedButton(
            onPressed: disconnect,
            style: ElevatedButton.styleFrom(
              primary: Colors.red,
              padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: Text(
              'Disconnect',
              style: TextStyle(
                fontSize: 18,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ConnectingScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.yellow,
            ),
            child: Icon(
              Icons.hourglass_bottom,
              color: Colors.white,
              size: 100,
            ),
          ),
          SizedBox(height: 20),
          Text(
            'Connecting...',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 10),
        ],
      ),
    );
  }
}

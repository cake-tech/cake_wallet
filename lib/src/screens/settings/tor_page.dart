import 'dart:async';

import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/store/app_store.dart';
import 'package:cake_wallet/themes/utils/custom_theme_colors.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:flutter/material.dart';
// import 'package:tor/tor.dart';

class TorPage extends BasePage {
  final AppStore appStore;

  TorPage(this.appStore);

  @override
  Widget body(BuildContext context) {
    return TorPageBody(appStore);
  }
}

class TorPageBody extends StatefulWidget {
  final AppStore appStore;

  const TorPageBody(this.appStore, {Key? key}) : super(key: key);

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

    // await Tor.init();
    //
    // // Start the proxy
    // await Tor.instance.start();
    //
    // // Toggle started flag.
    // setState(() {
    //   torEnabled = Tor.instance.enabled; // Update flag
    //   connecting = false;
    // });
    //
    // final node = widget.appStore.settingsStore.getCurrentNode(widget.appStore.wallet!.type);
    // if (node.socksProxyAddress?.isEmpty ?? true) {
    //   node.socksProxyAddress = "${InternetAddress.loopbackIPv4.address}:${Tor.instance.port}";
    // }
    // widget.appStore.wallet!.connectToNode(node: node);

    printV('Done awaiting; tor should be running');
  }

  Future<void> endTor() async {
    //   // Start the proxy
    //   Tor.instance.disable();
    //
    //   // Toggle started flag.
    //   setState(() {
    //     torEnabled = Tor.instance.enabled; // Update flag
    //   });
    //
    //   printV('Done awaiting; tor should be stopped');
  }
  //
  // @override
  // void initState() {
  //   super.initState();
  //
  //   torEnabled = Tor.instance.enabled;
  // }

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
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).colorScheme.primary,
              ),
              child: Icon(
                Icons.lock,
                color: Theme.of(context).colorScheme.onPrimary,
                size: 100,
              ),
            ),
            SizedBox(height: 48),
            Text(
              'Connect to Tor',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            SizedBox(height: 16),
            Text(
              'Your connection to the Tor network ensures privacy and security.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 48),
            ElevatedButton(
              onPressed: connect,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Connect',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 18,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
              ),
            ),
          ],
        ),
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
              color: CustomThemeColors.syncGreen,
            ),
            child: Icon(
              Icons.check,
              color: Theme.of(context).colorScheme.onPrimary,
              size: 100,
            ),
          ),
          SizedBox(height: 20),
          Text(
            'Connected to Tor',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
          ),
          SizedBox(height: 10),
          Text(
            'You are currently connected to the Tor network.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 30),
          ElevatedButton(
            onPressed: disconnect,
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Disconnect',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 18,
                    color: Theme.of(context).colorScheme.onPrimary,
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
              color: CustomThemeColors.syncYellow,
            ),
            child: Icon(
              Icons.hourglass_bottom,
              color: Theme.of(context).colorScheme.onPrimary,
              size: 100,
            ),
          ),
          SizedBox(height: 20),
          Text(
            'Connecting...',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
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

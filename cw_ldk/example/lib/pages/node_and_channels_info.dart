import 'package:flutter/material.dart';

class NodeAndChannelInfoPage extends StatefulWidget {
  @override
  State<NodeAndChannelInfoPage> createState() => _NodeAndChannelInfoState();
}

class _NodeAndChannelInfoState extends State<NodeAndChannelInfoPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text("Node and Channel Info")),
        body: Center(child: Text("Node and Channel Info")));
  }
}

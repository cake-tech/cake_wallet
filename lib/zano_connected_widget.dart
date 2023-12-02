import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:cake_wallet/zano.dart';
import 'package:cw_zano/api/model/destination.dart';
import 'package:cw_zano/api/model/get_wallet_info_result.dart';
import 'package:cw_zano/api/model/get_wallet_status_result.dart';
import 'package:cw_zano/api/model/history.dart';
import 'package:cw_zano/api/model/transfer_params.dart';
import 'package:flutter/material.dart';
import 'package:cw_zano/api/calls.dart' as calls;
import 'package:flutter/services.dart';

class ConnectedWidget extends StatefulWidget {
  final String address;
  const ConnectedWidget({super.key, required this.address});
  static const route = 'connected';

  @override
  State<ConnectedWidget> createState() => _ConnectedWidgetState();
}

class _ConnectedWidgetState extends State<ConnectedWidget> {
  Timer? _longRefreshTimer;
  GetWalletStatusResult? _gwsr;
  int? _txFee;
  final int _mixin = 10;
  late final TextEditingController _destinationAddress =
      TextEditingController(text: widget.address);
  static const defaultAmount = 1.0;
  late final TextEditingController _amount = TextEditingController(text: defaultAmount.toString());
  late String _amountFormatted = _mulBy10_12(defaultAmount);
  late final TextEditingController _paymentId = TextEditingController();
  late final TextEditingController _comment = TextEditingController(text: "test");
  bool _pushPayer = false;
  bool _hideReceiver = true;
  String _transferResult = '';
  List<History>? _transactions;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // _getWalletStatus returning true if it's in long refresh
      // in a long refresh we keep requesting _getWalletStatus until we get false
      if (_getWalletStatus()) {
        _longRefreshTimer = Timer.periodic(Duration(milliseconds: 1000), (timer) {
          if (!_getWalletStatus()) {
            _longRefreshTimer!.cancel();
            debugPrint('cancelling get wallet status timer');
            _getWalletInfo();
          }
        });
      }
      //_getWalletInfo();
    });
  }

  @override
  void dispose() {
    //_timer.cancel();
    // _myAddress.dispose();
    // _seed.dispose();
    _destinationAddress.dispose();
    _amount.dispose();
    _paymentId.dispose();
    _comment.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
            title: Text('Version $version'),
            actions: [
              IconButton(
                icon: Icon(Icons.close),
                onPressed: () {
                  close();
                  Navigator.of(context).pushReplacementNamed(DisconnectedWidget.route);
                },
              )
            ],
            bottom: TabBar(
              tabs: [
                Tab(text: 'Main'),
                Tab(text: 'Transfer'),
                Builder(builder: (context) {
                  if (lwr != null && lwr!.recentHistory.history != null) {
                    return Tab(text: 'History (${lwr!.recentHistory.history!.length})');
                  }
                  return Tab(text: 'History');
                }),
                Tab(text: 'Transactions')
              ],
            )),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: TabBarView(
              children: [
                _mainTab(context),
                _transferTab(context),
                _historyTab(),
                _transactionsTab(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _transactionsTab() {
    return Column(children: [
      TextButton(onPressed: _getTransactions, child: Text('Update list of Transactions')),
      Expanded(child: _transactionsListView(_transactions)),
    ]);
  }

  Widget _historyTab() {
    if (lwr == null) return Text("Empty");
    return _transactionsListView(lwr!.recentHistory.history);
  }

  ListView _transactionsListView(List<History>? list) {
    return ListView.builder(
      itemCount: list != null ? list.length : 0,
      itemBuilder: (context, index) {
        final item = list![index];
        late String addr;
        if (item.remoteAddresses.isNotEmpty) {
          addr = _shorten(item.remoteAddresses.first);
        } else {
          addr = "???";
        }
        return Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text("${index + 1}. ${_dateTime(item.timestamp)} Remote addr: $addr"),
                if (item.remoteAddresses.isNotEmpty)
                  IconButton(
                    onPressed: () =>
                        Clipboard.setData(ClipboardData(text: item.remoteAddresses.first)),
                    icon: Icon(Icons.copy),
                  ),
                if (item.remoteAliases.isNotEmpty) Text(" (${item.remoteAliases.first})"),
              ],
            ),
            Text("  txHash: ${item.txHash} comment: ${item.comment}"),
            Text(
                "  paymentId: ${item.paymentId} height: ${item.height} fee: ${_divBy10_12(item.fee)}"),
            if (item.employedEntries.receive.isNotEmpty)
              Text("  Receive", style: TextStyle(fontWeight: FontWeight.bold)),
            for (int i = 0; i < item.employedEntries.receive.length; i++)
              Text(
                  '  ${item.employedEntries.receive[i].index}. ${_assetName(item.employedEntries.receive[i].assetId)} ${_divBy10_12(item.employedEntries.receive[i].amount)}'),
            if (item.employedEntries.send.isNotEmpty)
              Text("  Spent", style: TextStyle(fontWeight: FontWeight.bold)),
            for (int i = 0; i < item.employedEntries.send.length; i++)
              Text(
                  '  ${item.employedEntries.send[i].index}. ${_assetName(item.employedEntries.send[i].assetId)} ${_divBy10_12(item.employedEntries.send[i].amount)}'),
            if (item.subtransfers.isNotEmpty)
              Text("  Subtransfers", style: TextStyle(fontWeight: FontWeight.bold)),
            for (int i = 0; i < item.subtransfers.length; i++)
              Text(
                  '  ${item.subtransfers[i].isIncome ? 'In' : 'Out'}. ${_assetName(item.subtransfers[i].assetId)} ${_divBy10_12(item.subtransfers[i].amount)}'),
            Divider(),
          ],
        );
      },
    );
  }

  Widget _transferTab(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Remote Address ', style: TextStyle(fontWeight: FontWeight.bold)),
              Expanded(
                child: TextField(
                  controller: _destinationAddress,
                ),
              ),
              IconButton(
                  onPressed: () => Clipboard.setData(ClipboardData(text: _destinationAddress.text)),
                  icon: Icon(Icons.copy)),
              IconButton(
                  onPressed: () async {
                    final clipboard = await Clipboard.getData("text/plain");
                    if (clipboard == null || clipboard.text == null) return;
                    setState(() {
                      _destinationAddress.text = clipboard.text!;
                    });
                  },
                  icon: Icon(Icons.paste)),
            ],
          ),
          Row(
            children: [
              //  ${lwr!.wi.address}
              Text('Amount ', style: TextStyle(fontWeight: FontWeight.bold)),
              Expanded(
                child: TextField(
                  controller: _amount,
                  onChanged: (value) => setState(() {
                    _amountFormatted = _mulBy10_12(double.parse(value));
                  }),
                ),
              ),
              Text("= ${_amountFormatted}"),
              IconButton(
                  onPressed: () => Clipboard.setData(ClipboardData(text: _amount.text)),
                  icon: Icon(Icons.copy)),
            ],
          ),
          if (_txFee != null)
            Text('Fee: ${_divBy10_12(_txFee!)} (${_txFee!})')
          else
            Text("Pls get Tx Fee before transfer!"),
          Text('Mixin: $_mixin'),
          Row(children: [
            Text('Payment Id ', style: TextStyle(fontWeight: FontWeight.bold)),
            Expanded(child: TextField(controller: _paymentId)),
          ]),
          Row(children: [
            Text('Comment ', style: TextStyle(fontWeight: FontWeight.bold)),
            Expanded(child: TextField(controller: _comment)),
          ]),
          Row(
            children: [
              Text('Push Payer ', style: TextStyle(fontWeight: FontWeight.bold)),
              Checkbox(
                  value: _pushPayer,
                  onChanged: (value) => setState(() => _pushPayer = value ?? false)),
            ],
          ),
          Row(
            children: [
              Text('Hide Receiver ', style: TextStyle(fontWeight: FontWeight.bold)),
              Checkbox(
                  value: _hideReceiver,
                  onChanged: (value) => setState(() => _hideReceiver = value ?? false)),
            ],
          ),
          TextButton(onPressed: _transfer, child: Text('Transfer')),
          const SizedBox(height: 16),
          Text('Transfer result $_transferResult'),
        ],
      ),
    );
  }

  Widget _mainTab(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Wallet Info', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(width: 16),
              TextButton(onPressed: _getWalletInfo, child: Text('Update WI & TxFee')),
            ],
          ),
          Row(
            children: [
              Text('My Address ', style: TextStyle(fontWeight: FontWeight.bold)),
              Expanded(
                  child: Text(
                widget.address,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )),
              IconButton(
                  onPressed: () => Clipboard.setData(ClipboardData(text: widget.address)),
                  icon: Icon(Icons.copy)),
            ],
          ),
          for (final balance in balances)
            Text(
                'Balance (${balance.assetInfo.ticker}) total: ${_divBy10_12(balance.total)}, unlocked: ${_divBy10_12(balance.unlocked)}'),
          Row(
            children: [
              Text('Seed ', style: TextStyle(fontWeight: FontWeight.bold)),
              Expanded(child: Text(seed, maxLines: 1, overflow: TextOverflow.ellipsis)),
              IconButton(
                  onPressed: () => Clipboard.setData(ClipboardData(text: seed)),
                  icon: Icon(Icons.copy)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text('Wallet Status', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(width: 16),
              TextButton(onPressed: _getWalletStatus, child: Text('Update')),
            ],
          ),
          if (_gwsr != null) ...[
            Row(
              children: [
                Expanded(child: Text('Daemon Height ${_gwsr!.currentDaemonHeight}')),
                Expanded(child: Text('Wallet Height ${_gwsr!.currentWalletHeight}')),
              ],
            ),
            Row(
              children: [
                Expanded(child: Text('Daemon Connected ${_gwsr!.isDaemonConnected}')),
                Expanded(child: Text('In Long Refresh ${_gwsr!.isInLongRefresh}')),
              ],
            ),
            Row(
              children: [
                Expanded(child: Text('Progress ${_gwsr!.progress}')),
                Expanded(child: Text('WalletState ${_gwsr!.walletState}')),
              ],
            ),
          ],
          const SizedBox(height: 16),
          if (_txFee != null) Text('Tx Fee: ${_divBy10_12(_txFee!)} (${_txFee!})'),
          TextButton(
              onPressed: () {
                close();
                Navigator.of(context).pushReplacementNamed(DisconnectedWidget.route);
              },
              child: Text('Disconnect')),
        ],
      ),
    );
  }

  Future<void> _transfer() async {
    final result = await calls.transfer(
        hWallet,
        TransferParams(
          destinations: [
            Destination(
              amount: _mulBy10_12(double.parse(_amount.text)),
              address: _destinationAddress.text,
              assetId: assetIds.keys.first,
            )
          ],
          fee: _txFee!,
          mixin: _mixin,
          paymentId: _paymentId.text,
          comment: _comment.text,
          pushPayer: _pushPayer,
          hideReceiver: _hideReceiver,
        ));
    debugPrint('transfer result $result');
    final map = jsonDecode(result);
    if (map['result'] == null) {
      setState(() => _transferResult = 'empty result');
    } else {
      if (map['result']['error'] != null) {
        setState(() => _transferResult =
            "error code ${map['result']['error']['code']} message ${map['result']['error']['message']} ");
      } else if (map['result']['result'] != null) {
        setState(() => _transferResult =
            "transfer tx hash ${map['result']['result']['tx_hash']} size ${map['result']['result']['tx_size']} ");
      }
    }
  }

  bool _getWalletStatus() {
    final json = calls.getWalletStatus(hWallet);
    if (json == walletWrongId) {
      debugPrint('error $walletWrongId');
      setState(() => _gwsr = null);
      return false;
    }
    try {
      setState(() {
        _gwsr = GetWalletStatusResult.fromJson(jsonDecode(json) as Map<String, dynamic>);
      });
      return _gwsr!.isInLongRefresh;
    } catch (e) {
      debugPrint('exception $e');
      setState(() => _gwsr = null);
      return false;
    }
  }

  void _getWalletInfo() {
    final result = GetWalletInfoResult.fromJson(
        jsonDecode(calls.getWalletInfo(hWallet)) as Map<String, dynamic>);
    final fee = calls.getCurrentTxFee(0);
    setState(() {
      balances = result.wi.balances;
      seed = result.wiExtended.seed;
      _txFee = fee;
    });
    // setState(() {
    //   _gwsr = GetWalletStatusResult.fromJson(
    //       jsonDecode(calls.getWalletStatus(hWallet)) as Map<String, dynamic>);
    // });
  }

  Future<void> _getTransactions() async {
    final result = await calls.getRecentTxsAndInfo(hWallet: hWallet, offset: 0, count: 30);
    final map = jsonDecode(result);
    if (map == null || map["result"] == null || map["result"]["result"] == null) {
      setState(() => _transactions = null);
      return;
    }
    setState(() => _transactions = map["result"]["result"]["transfers"] == null
        ? null
        : (map["result"]["result"]["transfers"] as List<dynamic>)
            .map((e) => History.fromJson(e as Map<String, dynamic>))
            .toList());
  }

  String _divBy10_12(int value) {
    return (value / pow(10, 12)).toString();
  }

  String _mulBy10_12(double value) {
    var str = (value * pow(10, 12)).toString();
    if (str.contains('.')) str = str.split('.')[0];
    return str;
  }

  String _shorten(String someId) {
    if (someId.length < 9) return someId;
    return '${someId.substring(0, 4).toUpperCase()}...${someId.substring(someId.length - 2)}';
  }

  String _assetName(String assetId) {
    if (assetIds[assetId] != null) {
      return assetIds[assetId]!;
    } else {
      return _shorten(assetId);
    }
  }

  String _dateTime(int timestamp) {
    DateTime date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    return '${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  Widget _row(
          String first, String second, String third, String forth, String fifth, String sixth) =>
      Row(
        children: [
          Expanded(child: Text(first)),
          Expanded(flex: 2, child: Text(second)),
          Expanded(flex: 2, child: Text(third)),
          Expanded(flex: 3, child: Text(forth)),
          Expanded(flex: 3, child: Text(fifth)),
          Expanded(child: Text(sixth)),
        ],
      );
}

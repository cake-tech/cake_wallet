import 'package:xelis_dart_sdk/xelis_dart_sdk.dart' as xelis_sdk;

abstract class Event {
  const Event();
}

class NewTopoheight extends Event {
  final int height;
  const NewTopoheight(this.height);
}

class NewTransaction extends Event {
  final xelis_sdk.TransactionEntry tx;
  const NewTransaction(this.tx);
}

class BalanceChanged extends Event {
  final String asset;
  final int balance;
  const BalanceChanged(this.asset, this.balance);
}

class Online extends Event {
  const Online();
}

class Offline extends Event {
  const Offline();
}

class Rescan extends Event {
  final int startTopoheight;
  const Rescan(this.startTopoheight);
}

class HistorySynced extends Event {
  final int topoheight;
  const HistorySynced(this.topoheight);
}

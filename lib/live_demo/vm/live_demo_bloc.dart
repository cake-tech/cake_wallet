import 'package:bloc/bloc.dart';
import 'package:cake_wallet/live_demo/client/live_demo_client.dart';
import 'package:cake_wallet/view_model/wallet_creation_vm.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:meta/meta.dart';

part 'live_demo_event.dart';
part 'live_demo_state.dart';

class NewWalletDefinition {
  final String name;
  final WalletType type;

  NewWalletDefinition(this.name, this.type);
}

class LiveDemoBloc extends Bloc<LiveDemoEvent, LiveDemoState> {
  final LiveDemoClient client;
  final WalletCreationVM walletCreationVM;

  LiveDemoBloc({required this.client, required this.walletCreationVM}) : super(LiveDemoInitial()) {
    on<ConnectionRequested>(_onConnectionRequested);
  }

  void _onConnectionRequested(ConnectionRequested event, Emitter<LiveDemoState> emit) async {
    emit(LiveDemoConfiguring("connecting"));
    client.connect(event.host, event.port);

    emit(LiveDemoConfiguring("downloading video"));
    client.ensureVideoInitialized();
    
    emit(LiveDemoConfiguring("fetching config"));
    final config = await client.getConfig();
    final List<NewWalletDefinition> walletDefs = (config["wallets"] as List<Map<String, String>>)
        .map((item) {
          final type = stringToWalletType(item["type"] ?? "");
          if (type == null) return null;
          final name = item["name"] ?? "${walletTypeToString(type)} Wallet";

          return NewWalletDefinition(name, type);
        })
        .whereType<NewWalletDefinition>()
        .toList();
    
    emit(LiveDemoConfiguring("creating wallets"));
    for(final def in walletDefs) {
      walletCreationVM.name = def.name;
      walletCreationVM.type = def.type;
    }
  }
}
